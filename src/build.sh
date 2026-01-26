#!/bin/bash

#==========================
# Set up the environment
#==========================
set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source $SCRIPT_DIR/shared.sh

# Store original arguments
ORIGINAL_ARGS=("$@")

# Parse command line arguments to check if config file is provided
CONFIG_JSON=""
for arg in "${ORIGINAL_ARGS[@]}"; do
    if [[ "$arg" == "-c" || "$arg" == "--config" ]]; then
        # Get next argument as config file
        for i in "${!ORIGINAL_ARGS[@]}"; do
            if [[ "${ORIGINAL_ARGS[$i]}" == "$arg" ]]; then
                CONFIG_JSON="${ORIGINAL_ARGS[$((i+1))]}"
                break
            fi
        done
        break
    fi
done

# Only source args.sh if not building from config (config will reload it)
if [ -z "$CONFIG_JSON" ]; then
source $SCRIPT_DIR/args.sh
fi

function bind_signal() {
    print_ok "Bind signal..."
    trap umount_on_exit EXIT
    judge "Bind signal"
}

function clean() {
    # This clean function is used to clean up the places where current build may touch and create
    print_ok "Cleaning up..."
    sudo umount new_building_os/sys || sudo umount -lf new_building_os/sys || true
    sudo umount new_building_os/proc || sudo umount -lf new_building_os/proc || true
    sudo umount new_building_os/dev || sudo umount -lf new_building_os/dev || true
    sudo umount new_building_os/run || sudo umount -lf new_building_os/run || true
    sudo rm -rf new_building_os || true
    judge "Clean up rootfs"
    sudo rm -rf image || true
    judge "Clean up image"
    sudo rm -f $TARGET_NAME.iso || true
    judge "Clean up iso"
}

function setup_host() {
    print_ok "Setting up host environment..."
    
    # Use install-deps.sh script for dependency installation
    print_ok "Installing build dependencies using scripts/install-deps.sh..."
    ARCH=$TARGET_ARCH sudo bash $SCRIPT_DIR/../scripts/install-deps.sh
    judge "Install required tools"

    print_ok "Creating new_building_os directory..."
    sudo mkdir -p new_building_os
    judge "Create new_building_os directory"

    print_ok "Setting up mods executable..."
    find . -type f -name "*.sh" -exec chmod +x {} \;
    judge "Set up mods executable"
}

function download_base_system() {
    # Configure apt-cacher-ng proxy if set
    DEBOOTSTRAP_ENV="DEBIAN_FRONTEND=noninteractive"
    if [ -n "$APT_CACHER_NG_URL" ]; then
        print_ok "Using apt-cacher-ng proxy: $APT_CACHER_NG_URL"
        export http_proxy="$APT_CACHER_NG_URL"
        export https_proxy="$APT_CACHER_NG_URL"
        export HTTP_PROXY="$APT_CACHER_NG_URL"
        export HTTPS_PROXY="$APT_CACHER_NG_URL"
        DEBOOTSTRAP_ENV="$DEBOOTSTRAP_ENV http_proxy=$APT_CACHER_NG_URL https_proxy=$APT_CACHER_NG_URL"
    fi
    
    print_ok "Calling debootstrap to download base Ubuntu system for $TARGET_ARCH..."
    print_warn "This may take 5-15 minutes depending on your network speed..."
    print_warn "Downloading from: $BUILD_UBUNTU_MIRROR"
    print_warn "Target version: $TARGET_UBUNTU_VERSION"
    
    # Use verbose mode to show progress
    sudo $DEBOOTSTRAP_ENV debootstrap \
        --arch=$TARGET_ARCH \
        --variant=minbase \
        --include=git \
        --verbose \
        $TARGET_UBUNTU_VERSION \
        new_building_os \
        $BUILD_UBUNTU_MIRROR
    judge "Download base system"
}

function mount_folers() {
    print_ok "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    judge "Reload systemd daemon"

    print_ok "Mounting /dev /run from host to new_building_os..."
    sudo mount --bind /dev new_building_os/dev
    sudo mount --bind /run new_building_os/run
    judge "Mount /dev /run"

    print_ok "Mounting /proc /sys /dev/pts within chroot..."
    sudo chroot new_building_os mount none -t proc /proc
    sudo chroot new_building_os mount none -t sysfs /sys
    sudo chroot new_building_os mount none -t devpts /dev/pts
    judge "Mount /proc /sys /dev/pts"

    # Copy DNS configuration from host so chroot can resolve hostnames
    print_ok "Copying DNS configuration from host..."
    if [ -f /etc/resolv.conf ]; then
        sudo cp /etc/resolv.conf new_building_os/etc/resolv.conf
        judge "Copy resolv.conf"
    else
        print_warn "Host /etc/resolv.conf not found, creating basic DNS config..."
        echo "nameserver 8.8.8.8" | sudo tee new_building_os/etc/resolv.conf > /dev/null
        echo "nameserver 8.8.4.4" | sudo tee -a new_building_os/etc/resolv.conf > /dev/null
        judge "Create basic resolv.conf"
    fi

    # Configure apt-cacher-ng proxy in chroot if set
    # Use 127.0.0.1 instead of localhost to avoid DNS dependency
    # Note: HTTPS repositories (like Mozilla PPA) bypass proxy to avoid 403 errors
    if [ -n "$APT_CACHER_NG_URL" ]; then
        print_ok "Configuring apt-cacher-ng proxy in chroot for both http and https..."
        sudo mkdir -p new_building_os/etc/apt/apt.conf.d
        # Replace localhost with 127.0.0.1 to avoid DNS resolution issues
        PROXY_URL=$(echo "$APT_CACHER_NG_URL" | sed 's/localhost/127.0.0.1/g')
        echo "Acquire::http::Proxy \"$PROXY_URL\";" | sudo tee new_building_os/etc/apt/apt.conf.d/01proxy > /dev/null
        echo "Acquire::https::Proxy \"$PROXY_URL\";" | sudo tee -a new_building_os/etc/apt/apt.conf.d/01proxy > /dev/null
        judge "Configure apt proxy in chroot"
    fi

    print_ok "Copying mods to new_building_os/root..."
    sudo cp -r $SCRIPT_DIR/mods new_building_os/root/mods
    sudo cp ./args.sh   new_building_os/root/mods/args.sh
    sudo cp ./shared.sh new_building_os/root/mods/shared.sh
}

function run_chroot() {
    print_ok "Running install_all_mods.sh in new_building_os..."
    print_warn "============================================"
    print_warn "   The following will run in chroot ENV!"
    print_warn "============================================"
    sudo chroot new_building_os /usr/bin/env DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-readline} /root/mods/install_all_mods.sh -
    print_warn "============================================"
    print_warn "   chroot ENV execution completed!"
    print_warn "============================================"
    judge "Run install_all_mods.sh in new_building_os"

    print_ok "Sleeping for 5 seconds to allow chroot to exit cleanly..."
    sleep 5
}

function umount_folers() {
    print_ok "Cleaning mods from new_building_os/root..."
    sudo rm -rf new_building_os/root/mods
    judge "Clean up new_building_os /root/mods"

    print_ok "Unmounting /proc /sys /dev/pts within chroot..."
    # Use lazy unmount to handle busy mounts
    sudo chroot new_building_os umount -lf /dev/pts 2>/dev/null || true
    sudo chroot new_building_os umount -lf /sys 2>/dev/null || true
    sudo chroot new_building_os umount -lf /proc 2>/dev/null || true
    judge "Unmount /proc /sys /dev/pts"

    print_ok "Unmounting /dev /run outside of chroot..."
    sudo umount -lf new_building_os/dev 2>/dev/null || true
    sudo umount -lf new_building_os/run 2>/dev/null || true
    judge "Unmount /dev /run /proc /sys"
}

function build_iso() {
    print_ok "Building ISO image..."

    print_ok "Creating image directory..."
    # Unmount any existing EFI boot image mounts before removing directory
    if mountpoint -q "$SCRIPT_DIR/image/boot-prep/efi" 2>/dev/null; then
        print_ok "Unmounting existing EFI boot image mount..."
        sudo umount -lf "$SCRIPT_DIR/image/boot-prep/efi" 2>/dev/null || true
    fi
    sudo rm -rf image
    mkdir -p image/{casper,boot-prep,.disk}
    judge "Create image directory"

    # Verify kernel files exist before proceeding
    print_ok "Verifying kernel files exist..."
    if [ ! -d "new_building_os/boot" ]; then
        print_error "new_building_os/boot directory does not exist!"
        exit 1
    fi
    
    if ! ls new_building_os/boot/vmlinuz-* >/dev/null 2>&1; then
        print_error "No kernel files (vmlinuz) found in new_building_os/boot/"
        print_error "This usually means kernel installation failed during mod execution."
        print_error "Contents of new_building_os/boot/:"
        ls -la new_building_os/boot/ || true
        print_error "Please check mod 08-casper-and-kernel-install-mod for errors."
        exit 1
    fi
    
    if ! ls new_building_os/boot/initrd.img-* >/dev/null 2>&1; then
        print_error "No initrd files found in new_building_os/boot/"
        print_error "Contents of new_building_os/boot/:"
        ls -la new_building_os/boot/ || true
        print_error "Please check mod 80-initramfs-update for errors."
        exit 1
    fi

    # copy kernel files (architecture-specific)
    print_ok "Copying kernel files as /casper/vmlinuz and /casper/initrd..."
    
    # Find the latest kernel version (works for both amd64 and arm64)
    KERNEL_VERSION=$(ls -1 new_building_os/boot/vmlinuz-*-*-generic 2>/dev/null | sort -V | tail -1 | sed 's|.*/vmlinuz-||')
    
    # Fallback: try without generic suffix if not found
    if [ -z "$KERNEL_VERSION" ]; then
        KERNEL_VERSION=$(ls -1 new_building_os/boot/vmlinuz-* 2>/dev/null | grep -v rescue | sort -V | tail -1 | sed 's|.*/vmlinuz-||')
    fi
    
    if [ -z "$KERNEL_VERSION" ]; then
        print_error "No kernel found in new_building_os/boot/"
        print_error "Available files:"
        ls -la new_building_os/boot/ | head -20
        exit 1
    fi
    
    print_ok "Using kernel version: $KERNEL_VERSION"
    sudo cp "new_building_os/boot/vmlinuz-${KERNEL_VERSION}" image/casper/vmlinuz
    sudo cp "new_building_os/boot/initrd.img-${KERNEL_VERSION}" image/casper/initrd
    judge "Copy kernel files"
    
    print_ok "Generating grub.cfg..."
    touch image/$TARGET_NAME
    cp $SCRIPT_DIR/args.sh image/$TARGET_NAME
    judge "Copy build args to disk"

    # Configurations are setup in new_building_os/usr/share/initramfs-tools/scripts/casper-bottom/25configure_init
    TRY_TEXT="Try and Install $TARGET_BUSINESS_NAME"
    TOGO_TEXT="$TARGET_BUSINESS_NAME To Go (Persistent on USB)"
    cat << EOF > image/boot-prep/grub.cfg

search --set=root --file /$TARGET_NAME

insmod all_video

set default="0"
set timeout=10

menuentry "$TRY_TEXT" {
   set gfxpayload=keep
   linux   /casper/vmlinuz boot=casper nopersistent quiet splash ---
   initrd  /casper/initrd
}

menuentry "$TRY_TEXT (Safe Graphics)" {
    set gfxpayload=keep
    linux   /casper/vmlinuz boot=casper nopersistent nomodeset ---
    initrd  /casper/initrd
}

menuentry "$TOGO_TEXT" {
   set gfxpayload=keep
   linux   /casper/vmlinuz boot=casper persistent quiet splash ---
   initrd  /casper/initrd
}

menuentry "$TOGO_TEXT (Safe Graphics)" {
    set gfxpayload=keep
    linux   /casper/vmlinuz boot=casper persistent nomodeset ---
    initrd  /casper/initrd
}

if [ "\$grub_platform" == "efi" ]; then
    menuentry "Boot from next volume" {
        exit 1
    }

    menuentry "UEFI Firmware Settings" {
        fwsetup
    }
fi
EOF
    judge "Generate grub.cfg"


    # generate manifest
    print_ok "Generating manifes for filesystem..."
    sudo chroot new_building_os dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest >/dev/null 2>&1
    judge "Generate manifest for filesystem"

    print_ok "Generating manifest for filesystem-desktop..."
    sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
    for pkg in $TARGET_PACKAGE_REMOVE; do
        sudo sed -i "/$pkg/d" image/casper/filesystem.manifest-desktop
    done
    judge "Generate manifest for filesystem-desktop"

    print_ok "Compressing rootfs as squashfs on /casper/filesystem.squashfs..."
    sudo mksquashfs new_building_os image/casper/filesystem.squashfs \
        -noappend -no-duplicates -no-recovery \
        -wildcards -b 1M \
        -comp zstd -Xcompression-level 6 \
        -e "var/cache/apt/archives/*" \
        -e "root/*" \
        -e "root/.*" \
        -e "tmp/*" \
        -e "tmp/.*" \
        -e "swapfile"
    judge "Compress rootfs"

    print_ok "Verifying the integrity of filesystem.squashfs..."
    if sudo unsquashfs -s image/casper/filesystem.squashfs; then
        print_ok "Verification successful. The file appears to be valid."
    else
        print_err "Verification FAILED! The squashfs file is likely corrupt."
        exit 1
    fi
    
    print_ok "Generating filesystem.size on /casper/filesystem.size..."
    printf $(sudo du -sx --block-size=1 new_building_os | cut -f1) > image/casper/filesystem.size
    judge "Generate filesystem.size"

    print_ok "Generating README.diskdefines..."
    ARCH_UPPER=$(echo "$TARGET_ARCH" | tr '[:lower:]' '[:upper:]')
    cat << EOF > image/README.diskdefines
#define DISKNAME  Try $TARGET_BUSINESS_NAME
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  $TARGET_ARCH
#define ARCH${TARGET_ARCH}  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF
    judge "Generate README.diskdefines"

    DATE=`TZ="UTC" date +"%y%m%d%H%M"`
    cat << EOF > image/README.md
# $TARGET_BUSINESS_NAME $TARGET_BUILD_VERSION

$TARGET_BUSINESS_NAME is a custom Ubuntu-based Linux distribution that offers a familiar and easy-to-use experience for anyone moving to Linux.

This image is built with the following configurations:

- **Language**: $LANG_MODE
- **Version**: $TARGET_BUILD_VERSION
- **Date**: $DATE

$TARGET_BUSINESS_NAME is distributed with Business Source License 1.1. You can find the license on [BSL 1.1](https://github.com/cortexlinux/cortex-distro/blob/$TARGET_BUILD_BRANCH/LICENSE).

## Please verify the checksum!!!

To verify the integrity of the image, you can calculate the md5sum of the image and compare it with the value in the file \`md5sum.txt\`.

To do this, run the following command in the terminal:

\`\`\`bash
md5sum -c md5sum.txt | grep -v 'OK'
\`\`\`

No output indicates that the image is correct.

## How to use

Press F12 to enter the boot menu when you start your computer. Select the USB drive to boot from.

## More information

For detailed instructions, please visit [$TARGET_BUSINESS_NAME Document](https://docs.cortexlinux.com/Install/System-Requirements.html).
EOF

    pushd $SCRIPT_DIR/image
    print_ok "Creating EFI boot image using live-build two-step approach..."
    
    # Set SOURCE_DATE_EPOCH for reproducible builds (default to current time if not set)
    if [ -z "${SOURCE_DATE_EPOCH:-}" ]; then
        SOURCE_DATE_EPOCH=$(date +%s)
    fi
    
    # Set UEFI Secure Boot mode (default to "auto" like live-build)
    UEFI_SECURE_BOOT="${UEFI_SECURE_BOOT:-auto}"
    
    (
        cd boot-prep && \
        rm -rf efi efiboot.img grub-efi-temp* grub-efi-temp-cfg 2>/dev/null || true
        if [ "$TARGET_ARCH" = "amd64" ] || [ "$TARGET_ARCH" = "arm64" ]; then
            # Use live-build's two-step approach: efi-image then binary_grub-efi
            if [ "$TARGET_ARCH" = "amd64" ]; then
                GRUB_PLATFORM="x86_64-efi"
                EFI_NAME="x64"
                BOOT_EFI="bootx64.efi"
                GRUB_MODULES_DIR="/usr/lib/grub/x86_64-efi"
                SB_EFI_PLATFORM="x86_64"
                SB_EFI_NAME="x64"
                SB_EFI_DEB="amd64"
            else
                GRUB_PLATFORM="arm64-efi"
                EFI_NAME="aa64"
                BOOT_EFI="bootaa64.efi"
                GRUB_MODULES_DIR="/usr/lib/grub/arm64-efi"
                SB_EFI_PLATFORM="arm64"
                SB_EFI_NAME="aa64"
                SB_EFI_DEB="arm64"
            fi
            
            print_ok "Step 1: Creating initial EFI boot image (like efi-image script)..."
            if [ ! -f "grub.cfg" ]; then
                print_error "grub.cfg not found in boot-prep directory!"
                exit 1
            fi
            
            # Use system GRUB modules (like live-build)
            if [ ! -d "$GRUB_MODULES_DIR" ]; then
                print_error "GRUB modules directory not found: $GRUB_MODULES_DIR"
                if [ "$TARGET_ARCH" = "amd64" ]; then
                    print_error "Please install grub-efi-amd64-bin package"
                else
                    print_error "Please install grub-efi-arm64-bin package"
                fi
                exit 1
            fi
            
            # Step 1: Create initial efi.img (like efi-image script)
            INITIAL_OUTDIR="grub-efi-temp-${GRUB_PLATFORM}"
            rm -rf "$INITIAL_OUTDIR"
            mkdir -p "$INITIAL_OUTDIR"
            
            GRUB_WORKDIR=$(mktemp -d)
            MEMDISK_IMG=$(mktemp)
            trap "sudo rm -rf $GRUB_WORKDIR $MEMDISK_IMG $INITIAL_OUTDIR grub-efi-temp grub-efi-temp-cfg" EXIT
            
            # Create boot/grub structure with grub.cfg (like live-build efi-image)
            sudo mkdir -p "$GRUB_WORKDIR/boot/grub"
            cat <<EOF | sudo tee "$GRUB_WORKDIR/boot/grub/grub.cfg" > /dev/null
search --file --set=root /.disk/info
set prefix=(\$root)/boot/grub
source \$prefix/$GRUB_PLATFORM/grub.cfg
EOF
            # Set timestamps (like live-build)
            find "$GRUB_WORKDIR" -newermt "$(date -d@${SOURCE_DATE_EPOCH} '+%Y-%m-%d %H:%M:%S')" -exec sudo touch '{}' -d@${SOURCE_DATE_EPOCH} ';' 2>/dev/null || true
            
            # Get partition modules list (like live-build)
            PARTITIONLIST=""
            for i in "$GRUB_MODULES_DIR"/part_*.mod; do
                if [ -f "$i" ]; then
                    PARTITIONLIST="$PARTITIONLIST $(basename "$i" .mod)"
                fi
            done
            
            # Create platform-specific grub.cfg (like live-build efi-image)
            mkdir -p "$INITIAL_OUTDIR/boot/grub/$GRUB_PLATFORM"
            cat <<EOF > "$INITIAL_OUTDIR/boot/grub/$GRUB_PLATFORM/grub.cfg"
if [ x\$grub_platform == xefi -a x\$lockdown != xy ] ; then
$(printf "    insmod %s\n" $PARTITIONLIST)
fi
source /boot/grub/grub.cfg
EOF
            
            # Create memdisk image (tar archive) with boot/grub structure
            (cd "$GRUB_WORKDIR" && sudo tar -cf - boot) > "$MEMDISK_IMG"
            
            # Create boot*.efi using grub-mkimage with memdisk (like live-build efi-image)
            print_ok "Creating $BOOT_EFI with grub-mkimage..."
            sudo grub-mkimage -O "$GRUB_PLATFORM" -m "$MEMDISK_IMG" \
                -o "$GRUB_WORKDIR/$BOOT_EFI" \
                -p '(memdisk)/boot/grub' \
                search iso9660 configfile normal memdisk tar $PARTITIONLIST fat
            
            # Set timestamp on EFI binary (like live-build)
            sudo touch "$GRUB_WORKDIR/$BOOT_EFI" -d@${SOURCE_DATE_EPOCH}
            
            # Create initial efi.img with just boot*.efi (like live-build efi-image)
            INITIAL_SIZE=$(( ($(stat -c %s "$GRUB_WORKDIR/$BOOT_EFI") / 1024 + 55) / 32 * 32 ))
            sudo mkfs.msdos -C "$INITIAL_OUTDIR/efi.img" $INITIAL_SIZE \
                -i $(printf "%08x" $((${SOURCE_DATE_EPOCH}%4294967296))) >/dev/null
            sudo mmd -i "$INITIAL_OUTDIR/efi.img" ::efi
            sudo mmd -i "$INITIAL_OUTDIR/efi.img" ::efi/boot
            sudo mcopy -m -i "$INITIAL_OUTDIR/efi.img" "$GRUB_WORKDIR/$BOOT_EFI" "::efi/boot/$BOOT_EFI"
            
            # Copy GRUB modules using grub-cpmodules logic (like live-build)
            print_ok "Copying GRUB modules..."
            # Copy .lst files
            sudo cp "$GRUB_MODULES_DIR"/*.lst "$INITIAL_OUTDIR/boot/grub/$GRUB_PLATFORM/" 2>/dev/null || true
            # Copy modules (excluding those already in the binary)
            for mod in "$GRUB_MODULES_DIR"/*.mod; do
                if [ -f "$mod" ]; then
                    modname=$(basename "$mod" .mod)
                    case "$modname" in
                        configfile|fshelp|iso9660|memdisk|search|search_fs_file|search_fs_uuid|search_label|tar)
                            # Already included in boot image
                            ;;
                        *)
                            sudo cp "$mod" "$INITIAL_OUTDIR/boot/grub/$GRUB_PLATFORM/"
                            ;;
                    esac
                fi
            done
            
            # Copy unicode font (like live-build)
            if [ -f /usr/share/grub/unicode.pf2 ]; then
                sudo cp -a /usr/share/grub/unicode.pf2 "$INITIAL_OUTDIR/boot/grub/"
            fi
            
            # Step 2: Create final efi.img (like binary_grub-efi)
            print_ok "Step 2: Creating final EFI boot image with secure boot support..."
            mkdir -p grub-efi-temp/EFI/boot
            
            # Extract boot*.efi from initial efi.img (like live-build binary_grub-efi line 173)
            sudo mcopy -m -n -i "$INITIAL_OUTDIR/efi.img" '::efi/boot/boot*.efi' grub-efi-temp/EFI/boot/
            
            # Copy everything from initial outdir (like live-build binary_grub-efi line 174)
            sudo cp -a "$INITIAL_OUTDIR"/* grub-efi-temp/
            
            # Secure Boot support (like live-build binary_grub-efi lines 195-213)
            if [ -r "/usr/lib/grub/${SB_EFI_PLATFORM}-efi-signed/gcd${SB_EFI_NAME}.efi.signed" -a \
                 -r "/usr/lib/shim/shim${SB_EFI_NAME}.efi.signed" -a \
                 "$UEFI_SECURE_BOOT" != "disable" ]; then
                print_ok "Secure Boot: Using signed GRUB and shim..."
                sudo cp -a "/usr/lib/grub/${SB_EFI_PLATFORM}-efi-signed/gcd${SB_EFI_NAME}.efi.signed" \
                    grub-efi-temp/EFI/boot/grub${SB_EFI_NAME}.efi
                sudo cp -a --dereference "/usr/lib/shim/shim${SB_EFI_NAME}.efi.signed" \
                    grub-efi-temp/EFI/boot/boot${SB_EFI_NAME}.efi
            elif [ ! -r "/usr/lib/grub/${SB_EFI_PLATFORM}-efi-signed/gcd${SB_EFI_NAME}.efi.signed" -a \
                   -r "/usr/lib/shim/shim${SB_EFI_NAME}.efi.signed" -a \
                   "$UEFI_SECURE_BOOT" = "auto" ]; then
                # Allow a shim-only scenario
                print_ok "Secure Boot: Using shim-only (user must enroll grub hash)..."
                sudo cp -a --dereference "/usr/lib/shim/shim${SB_EFI_NAME}.efi.signed" \
                    grub-efi-temp/EFI/boot/boot${SB_EFI_NAME}.efi
                sudo cp -a "/usr/lib/grub/${GRUB_PLATFORM}/monolithic/gcd${SB_EFI_NAME}.efi" \
                    grub-efi-temp/EFI/boot/grub${SB_EFI_NAME}.efi
                # Needed to allow the user to enroll the hash of grub*.efi
                sudo cp -a "/usr/lib/shim/mm${SB_EFI_NAME}.efi.signed" \
                    grub-efi-temp/EFI/boot/mm${SB_EFI_NAME}.efi 2>/dev/null || true
            else
                print_ok "Secure Boot: Disabled or not available, using unsigned GRUB..."
            fi
            
            # Create minimal grub.cfg for EFI partition (like live-build binary_grub-efi)
            mkdir -p grub-efi-temp-cfg
            cat <<EOF > grub-efi-temp-cfg/grub.cfg
search --set=root --file /.disk/info
set prefix=(\$root)/boot/grub
configfile (\$root)/boot/grub/grub.cfg
EOF
            # Set timestamp (like live-build)
            touch grub-efi-temp-cfg/grub.cfg -d@${SOURCE_DATE_EPOCH}
            
            # Calculate final EFI image size (like live-build binary_grub-efi lines 274-283)
            size=0
            for file in grub-efi-temp/EFI/boot/*.efi grub-efi-temp-cfg/grub.cfg; do
                if [ -f "$file" ]; then
                    size=$((size + $(stat -c %s "$file")))
                fi
            done
            # directories: EFI EFI/boot boot boot/grub
            size=$((size + 4096 * 4))
            blocks=$(((size / 1024 + 55) / 32 * 32))
            
            # Create final efi.img using mkfs.msdos (like live-build binary_grub-efi)
            print_ok "Creating final efi.img with calculated size ($blocks KB)..."
            rm -f grub-efi-temp/boot/grub/efi.img
            # The VOLID must be (truncated to) a 32bit hexadecimal number
            sudo mkfs.msdos -C grub-efi-temp/boot/grub/efi.img $blocks \
                -i $(printf "%08x" $((${SOURCE_DATE_EPOCH}%4294967296))) >/dev/null
            
            # Populate final efi.img using mcopy (like live-build binary_grub-efi)
            sudo mmd -i grub-efi-temp/boot/grub/efi.img ::EFI
            sudo mmd -i grub-efi-temp/boot/grub/efi.img ::EFI/boot
            sudo mcopy -m -o -i grub-efi-temp/boot/grub/efi.img grub-efi-temp/EFI/boot/*.efi "::EFI/boot"
            
            sudo mmd -i grub-efi-temp/boot/grub/efi.img ::boot
            sudo mmd -i grub-efi-temp/boot/grub/efi.img ::boot/grub
            sudo mcopy -m -o -i grub-efi-temp/boot/grub/efi.img grub-efi-temp-cfg/grub.cfg "::boot/grub"
            
            # Copy everything to ISO filesystem (like live-build binary_grub-efi line 329)
            print_ok "Copying EFI structure to ISO filesystem..."
            sudo mkdir -p ../EFI/BOOT
            sudo cp -r grub-efi-temp/EFI/boot/* ../EFI/BOOT/
            
            # Copy boot/grub structure to ISO filesystem (modules go here, NOT in efi.img)
            sudo mkdir -p "../boot/grub/$GRUB_PLATFORM"
            sudo cp -r grub-efi-temp/boot/grub/$GRUB_PLATFORM/* "../boot/grub/$GRUB_PLATFORM/" 2>/dev/null || true
            # We're already in boot-prep/ directory, so use grub.cfg directly
            if [ -f "grub.cfg" ]; then
                sudo cp grub.cfg ../boot/grub/grub.cfg
            else
                print_error "grub.cfg not found in boot-prep directory!"
                exit 1
            fi
            
            # Copy final efi.img to ISO filesystem
            sudo mkdir -p ../boot/grub
            sudo cp grub-efi-temp/boot/grub/efi.img ../boot/grub/efi.img
            
            # Create efiboot.img for appended partition (ARM64) or as temporary file
            sudo cp grub-efi-temp/boot/grub/efi.img efiboot.img
            
            # Set timestamps on ISO filesystem files
            find ../EFI ../boot -type f -newermt "$(date -d@${SOURCE_DATE_EPOCH} '+%Y-%m-%d %H:%M:%S')" -exec sudo touch '{}' -d@${SOURCE_DATE_EPOCH} ';' 2>/dev/null || true
            
            sudo rm -rf "$GRUB_WORKDIR" "$MEMDISK_IMG" "$INITIAL_OUTDIR" grub-efi-temp grub-efi-temp-cfg
            
            print_ok "EFI boot image created successfully"
        fi
    )
    judge "Create EFI boot image"

    # BIOS boot only for amd64
    if [ "$TARGET_ARCH" = "amd64" ]; then
        print_ok "Creating BIOS boot image on /boot-prep/bios.img..."
        grub-mkstandalone \
            --format=i386-pc \
            --output=boot-prep/core.img \
            --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
            --modules="linux16 linux normal iso9660 biosdisk search" \
            --locales="" \
            --fonts="" \
            "boot/grub/grub.cfg=boot-prep/grub.cfg"
        judge "Create BIOS boot image"

        print_ok "Creating hybrid boot image on /boot-prep/bios.img..."
        cat /usr/lib/grub/i386-pc/cdboot.img boot-prep/core.img > boot-prep/bios.img
        # Set timestamp (like live-build)
        touch boot-prep/bios.img -d@${SOURCE_DATE_EPOCH}
        # Clean up temporary core.img (not needed after creating bios.img)
        rm -f boot-prep/core.img
        judge "Create hybrid boot image"
    else
        print_ok "Skipping BIOS boot image (not supported for $TARGET_ARCH)"
    fi

    print_ok "Creating .disk/info..."
    echo "$TARGET_BUSINESS_NAME $TARGET_BUILD_VERSION $TARGET_UBUNTU_VERSION - Release $TARGET_ARCH ($(date +%Y%m%d))" | sudo tee .disk/info
    # Set timestamp (like live-build)
    sudo touch .disk/info -d@${SOURCE_DATE_EPOCH}
    judge "Create .disk/info"

    print_ok "Creating md5sum.txt..."
    sudo /bin/bash -c "(find . -type f -print0 | xargs -0 md5sum | grep -v -e 'md5sum.txt' -e 'bios.img' -e 'efiboot.img' -e 'boot-prep/core.img' > md5sum.txt)"
    sudo touch md5sum.txt -d@${SOURCE_DATE_EPOCH}
    judge "Create md5sum.txt"

    print_ok "Creating iso image on $SCRIPT_DIR/$TARGET_NAME.iso..."
    if [ "$TARGET_ARCH" = "amd64" ]; then
        # AMD64: Hybrid ISO with both BIOS and EFI boot
        # According to Debian wiki https://wiki.debian.org/RepackBootableISO, AMD64 needs:
        # - boot/grub/efi.img for El Torito EFI boot (already created in EFI step)
        # - isohybrid-gpt-basdat for EFI USB boot support
        # - isohybrid-apm-hfsplus for Apple compatibility
        # boot/grub/efi.img should already exist from EFI creation step
        
        sudo xorriso \
            -as mkisofs \
            -r \
            -iso-level 3 \
            -full-iso9660-filenames \
            -volid "$TARGET_NAME" \
            -J -J -joliet-long -cache-inodes \
            -eltorito-boot boot/grub/bios.img \
                -no-emul-boot \
                -boot-load-size 4 \
                -boot-info-table \
                --grub2-boot-info \
                --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
            -eltorito-alt-boot \
                -e boot/grub/efi.img \
                -no-emul-boot \
                -isohybrid-gpt-basdat \
                -isohybrid-apm-hfsplus \
            --modification-date=$(date --utc -d@${SOURCE_DATE_EPOCH} +%Y%m%d%H%M%S00) \
            -output "$SCRIPT_DIR/$TARGET_NAME.iso" \
            -m "boot-prep/efiboot.img" \
            -m "boot-prep/bios.img" \
            -graft-points \
                "/EFI/BOOT=EFI/BOOT" \
                "/boot/grub=boot/grub" \
                "/boot/grub/grub.cfg=boot-prep/grub.cfg" \
                "/boot/grub/bios.img=boot-prep/bios.img" \
                "."
    elif [ "$TARGET_ARCH" = "arm64" ]; then
        # ARM64: EFI-only ISO (no BIOS boot)
        # According to Debian wiki https://wiki.debian.org/RepackBootableISO and
        # Ask Ubuntu: https://askubuntu.com/questions/1110651/how-to-produce-an-iso-image-that-boots-only-on-uefi
        # ARM64 needs:
        # - Use --interval:appended_partition_2:all:: to avoid EFI image duplication (xorriso >= 1.4.6)
        #   This references the appended partition directly instead of storing it in ISO filesystem
        # - append_partition 2 0xef for USB boot support
        # - partition_cyl_align all for proper alignment
        # - partition_offset 16 for better partition editor compatibility
        # Note: This optimization saves a few MB by not duplicating the EFI image in the ISO filesystem
        
        sudo xorriso \
            -as mkisofs \
            -r \
            -iso-level 3 \
            -full-iso9660-filenames \
            -volid "$TARGET_NAME" \
            -J -joliet-long -cache-inodes \
            -e "--interval:appended_partition_2:all::" \
            -no-emul-boot \
            -append_partition 2 0xef boot-prep/efiboot.img \
            -partition_cyl_align all \
            -partition_offset 16 \
            --modification-date=$(date --utc -d@${SOURCE_DATE_EPOCH} +%Y%m%d%H%M%S00) \
            -output "$SCRIPT_DIR/$TARGET_NAME.iso" \
            -m "boot-prep/efiboot.img" \
            -graft-points \
                "/EFI/BOOT=EFI/BOOT" \
                "/boot/grub=boot/grub" \
                "/boot/grub/grub.cfg=boot-prep/grub.cfg" \
                "."
    fi
    judge "Create iso image"
    
    # Set timestamp on ISO image (like live-build)
    # Use sudo since ISO was created with sudo xorriso
    sudo touch "$SCRIPT_DIR/$TARGET_NAME.iso" -d@${SOURCE_DATE_EPOCH}

    print_ok "Moving iso image to $SCRIPT_DIR/dist/$TARGET_BUSINESS_NAME-$TARGET_BUILD_VERSION-$TARGET_ARCH-$LANG_MODE-$DATE.iso..."
    mkdir -p "$SCRIPT_DIR/dist"
    mv "$SCRIPT_DIR/$TARGET_NAME.iso" "$SCRIPT_DIR/dist/$TARGET_BUSINESS_NAME-$TARGET_BUILD_VERSION-$TARGET_ARCH-$LANG_MODE-$DATE.iso"
    # Set timestamp on final ISO (like live-build)
    sudo touch "$SCRIPT_DIR/dist/$TARGET_BUSINESS_NAME-$TARGET_BUILD_VERSION-$TARGET_ARCH-$LANG_MODE-$DATE.iso" -d@${SOURCE_DATE_EPOCH}
    judge "Move iso image"

    print_ok "Generating sha256 checksum..."
    HASH=`sha256sum "$SCRIPT_DIR/dist/$TARGET_BUSINESS_NAME-$TARGET_BUILD_VERSION-$TARGET_ARCH-$LANG_MODE-$DATE.iso" | cut -d ' ' -f 1`
    echo "SHA256: $HASH" > "$SCRIPT_DIR/dist/$TARGET_BUSINESS_NAME-$TARGET_BUILD_VERSION-$TARGET_ARCH-$LANG_MODE-$DATE.sha256"
    judge "Generate sha256 checksum"

    popd
}

function umount_on_exit() {
    sleep 2
    print_ok "Umount before exit..."
    # Use absolute paths and check if mounts exist before unmounting
    if mountpoint -q "$SCRIPT_DIR/new_building_os/sys" 2>/dev/null; then
        sudo umount "$SCRIPT_DIR/new_building_os/sys" || sudo umount -lf "$SCRIPT_DIR/new_building_os/sys" || true
    fi
    if mountpoint -q "$SCRIPT_DIR/new_building_os/proc" 2>/dev/null; then
        sudo umount "$SCRIPT_DIR/new_building_os/proc" || sudo umount -lf "$SCRIPT_DIR/new_building_os/proc" || true
    fi
    if mountpoint -q "$SCRIPT_DIR/new_building_os/dev" 2>/dev/null; then
        sudo umount "$SCRIPT_DIR/new_building_os/dev" || sudo umount -lf "$SCRIPT_DIR/new_building_os/dev" || true
    fi
    if mountpoint -q "$SCRIPT_DIR/new_building_os/run" 2>/dev/null; then
        sudo umount "$SCRIPT_DIR/new_building_os/run" || sudo umount -lf "$SCRIPT_DIR/new_building_os/run" || true
    fi
    # Also check for loop mounts (EFI boot image)
    if mountpoint -q "$SCRIPT_DIR/image/boot-prep/efi" 2>/dev/null; then
        sudo umount "$SCRIPT_DIR/image/boot-prep/efi" || sudo umount -lf "$SCRIPT_DIR/image/boot-prep/efi" || true
    fi
    print_ok "Umount cleanup completed"
}

function build_single() {
    # Build a single language configuration
cd $SCRIPT_DIR
bind_signal
clean
setup_host
download_base_system
mount_folers
run_chroot
umount_folers
build_iso
echo "$0 - Initial build is done!"
}

function build_from_config() {
    # Build from JSON config file (single language)
    local CONFIG_JSON="$1"
    
    if [[ ! -f "$CONFIG_JSON" ]]; then
        print_error "Configuration file $CONFIG_JSON does not exist."
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_ok "Installing jq for JSON parsing..."
        sudo apt-get update && sudo apt-get install -y jq
        judge "Install jq"
    fi
    
    # Extract language information from JSON (first entry)
    local lang_info=$(jq -c '.[0]' "$CONFIG_JSON")
    
    # Display summary of the language configuration for logging
    local LANG_MODE=$(echo "$lang_info" | jq -r '.lang_mode')
    echo "================================================="
    echo "[INFO] Building language: ${LANG_MODE}"
    echo "Configuration:"
    echo "$lang_info" | jq '.'
    echo "================================================="
    
    # Dynamically update all fields in args.sh
    # Get all keys from the language configuration
    local keys=$(echo "$lang_info" | jq -r 'keys[]')
    
    # For each key, update the corresponding environment variable in args.sh
    for key in $keys; do
        # Convert key to uppercase for environment variable naming
        local env_var=$(echo "$key" | tr '[:lower:]' '[:upper:]')
        # Get the value
        local value=$(echo "$lang_info" | jq -r --arg k "$key" '.[$k]')
        # Escape special characters for sed: &, \, and the delimiter #
        local escaped_value=$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/&/\\&/g; s/#/\\#/g')
        # Only update if the variable exists in args.sh (use # as delimiter to avoid conflicts)
        if grep -q "^export ${env_var}=" "$SCRIPT_DIR/args.sh"; then
            sed -i "s#^export ${env_var}=\".*\"#export ${env_var}=\"${escaped_value}\"#" $SCRIPT_DIR/args.sh
        else
            print_warn "Variable ${env_var} not found in args.sh, skipping..."
        fi
    done
    
    # Reload args.sh with updated values
    source $SCRIPT_DIR/args.sh
    
    # Build single language
    build_single
}

# =============   main  ================
# If config file is provided, build from config, otherwise build single
if [ -n "$CONFIG_JSON" ]; then
    echo "[INFO] Using configuration file '$CONFIG_JSON'."
    build_from_config "$CONFIG_JSON"
else
    build_single
fi
