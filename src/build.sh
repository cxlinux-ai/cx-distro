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
    if mountpoint -q "$SCRIPT_DIR/image/isolinux/efi" 2>/dev/null; then
        print_ok "Unmounting existing EFI boot image mount..."
        sudo umount -lf "$SCRIPT_DIR/image/isolinux/efi" 2>/dev/null || true
    fi
    sudo rm -rf image
    mkdir -p image/{casper,isolinux,.disk}
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
    cat << EOF > image/isolinux/grub.cfg

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
        -comp zstd -Xcompression-level 19 \
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
    print_ok "Creating EFI boot image on /isolinux/efiboot.img..."
    
    # Check available disk space before creating EFI image
    AVAILABLE_SPACE=$(df -BM "$SCRIPT_DIR/image" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/M//' || echo "0")
    if [ "$AVAILABLE_SPACE" -lt 50 ] 2>/dev/null; then
        print_error "Insufficient disk space. Need at least 50MB, have ${AVAILABLE_SPACE}MB"
        print_error "Please free up disk space and try again."
        exit 1
    fi
    
    (
        cd isolinux && \
        # Clean up any existing mount or directory first
        if mountpoint -q efi 2>/dev/null; then
            sudo umount -lf efi 2>/dev/null || true
        fi
        rm -rf efi efiboot.img 2>/dev/null || true
        # Increase EFI image size to 20MB to ensure enough space for GRUB files
        dd if=/dev/zero of=efiboot.img bs=1M count=20 2>/dev/null && \
        sudo mkfs.vfat -F 32 efiboot.img >/dev/null 2>&1 && \
        mkdir -p efi && \
        sudo mount -o loop efiboot.img efi && \
        sudo mkdir -p efi/EFI/BOOT && \
        if [ "$TARGET_ARCH" = "amd64" ]; then
            sudo grub-install --target=x86_64-efi --efi-directory=efi --boot-directory=efi/EFI/BOOT --uefi-secure-boot --removable --no-nvram
        elif [ "$TARGET_ARCH" = "arm64" ]; then
            sudo grub-install --target=arm64-efi --efi-directory=efi --boot-directory=efi/EFI/BOOT --uefi-secure-boot --removable --no-nvram
        fi && \
        sudo cp grub.cfg efi/EFI/BOOT/grub.cfg && \
        # Copy EFI/BOOT directory to ISO filesystem for ARM64 compatibility
        # Some UEFI implementations require EFI/BOOT in the ISO filesystem
        if [ "$TARGET_ARCH" = "arm64" ]; then
            print_ok "Copying EFI/BOOT directory to ISO filesystem for ARM64 UEFI compatibility..."
            sudo mkdir -p ../EFI/BOOT
            sudo cp -r efi/EFI/BOOT/* ../EFI/BOOT/
            judge "Copy EFI/BOOT to ISO filesystem"
        fi && \
        sudo umount efi && \
        rm -rf efi
    )
    judge "Create EFI boot image"

    # BIOS boot only for amd64
    if [ "$TARGET_ARCH" = "amd64" ]; then
        print_ok "Creating BIOS boot image on /isolinux/bios.img..."
        grub-mkstandalone \
            --format=i386-pc \
            --output=isolinux/core.img \
            --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
            --modules="linux16 linux normal iso9660 biosdisk search" \
            --locales="" \
            --fonts="" \
            "boot/grub/grub.cfg=isolinux/grub.cfg"
        judge "Create BIOS boot image"

        print_ok "Creating hybrid boot image on /isolinux/bios.img..."
        cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img
        judge "Create hybrid boot image"
    else
        print_ok "Skipping BIOS boot image (not supported for $TARGET_ARCH)"
        touch isolinux/bios.img
    fi

    print_ok "Creating .disk/info..."
    echo "$TARGET_BUSINESS_NAME $TARGET_BUILD_VERSION $TARGET_UBUNTU_VERSION - Release $TARGET_ARCH ($(date +%Y%m%d))" | sudo tee .disk/info
    judge "Create .disk/info"

    print_ok "Creating md5sum.txt..."
    sudo /bin/bash -c "(find . -type f -print0 | xargs -0 md5sum | grep -v -e 'md5sum.txt' -e 'bios.img' -e 'efiboot.img' > md5sum.txt)"
    judge "Create md5sum.txt"

    print_ok "Creating iso image on $SCRIPT_DIR/$TARGET_NAME.iso..."
    if [ "$TARGET_ARCH" = "amd64" ]; then
        # AMD64: Hybrid ISO with both BIOS and EFI boot
        sudo xorriso \
            -as mkisofs \
            -iso-level 3 \
            -full-iso9660-filenames \
            -volid "$TARGET_NAME" \
            -eltorito-boot boot/grub/bios.img \
                -no-emul-boot \
                -boot-load-size 4 \
                -boot-info-table \
                --eltorito-catalog boot/grub/boot.cat \
                --grub2-boot-info \
                --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
            -eltorito-alt-boot \
                -e EFI/efiboot.img \
                -no-emul-boot \
                -append_partition 2 0xef isolinux/efiboot.img \
            -output "$SCRIPT_DIR/$TARGET_NAME.iso" \
            -m "isolinux/efiboot.img" \
            -m "isolinux/bios.img" \
            -graft-points \
                "/EFI/efiboot.img=isolinux/efiboot.img" \
                "/boot/grub/grub.cfg=isolinux/grub.cfg" \
                "/boot/grub/bios.img=isolinux/bios.img" \
                "."
    elif [ "$TARGET_ARCH" = "arm64" ]; then
        # ARM64: EFI-only ISO (no BIOS boot)
        sudo xorriso \
            -as mkisofs \
            -iso-level 3 \
            -full-iso9660-filenames \
            -volid "$TARGET_NAME" \
            -eltorito-alt-boot \
                -e EFI/efiboot.img \
                -no-emul-boot \
                -append_partition 2 0xef isolinux/efiboot.img \
            -output "$SCRIPT_DIR/$TARGET_NAME.iso" \
            -m "isolinux/efiboot.img" \
            -graft-points \
                "/EFI/efiboot.img=isolinux/efiboot.img" \
                "/EFI/BOOT=EFI/BOOT" \
                "/boot/grub/grub.cfg=isolinux/grub.cfg" \
                "."
    fi
    judge "Create iso image"

    print_ok "Moving iso image to $SCRIPT_DIR/dist/$TARGET_BUSINESS_NAME-$TARGET_BUILD_VERSION-$TARGET_ARCH-$LANG_MODE-$DATE.iso..."
    mkdir -p "$SCRIPT_DIR/dist"
    mv "$SCRIPT_DIR/$TARGET_NAME.iso" "$SCRIPT_DIR/dist/$TARGET_BUSINESS_NAME-$TARGET_BUILD_VERSION-$TARGET_ARCH-$LANG_MODE-$DATE.iso"
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
    if mountpoint -q "$SCRIPT_DIR/image/isolinux/efi" 2>/dev/null; then
        sudo umount "$SCRIPT_DIR/image/isolinux/efi" || sudo umount -lf "$SCRIPT_DIR/image/isolinux/efi" || true
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
        # Get the value and escape any special characters
        local value=$(echo "$lang_info" | jq -r --arg k "$key" '.[$k]')
        local escaped_value=$(echo "$value" | sed 's/[\/&]/\\&/g')
        sed -i "s|^export ${env_var}=\".*\"|export ${env_var}=\"${escaped_value}\"|" $SCRIPT_DIR/args.sh
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
