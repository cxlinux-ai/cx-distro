set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Installing capser (live-boot)..."
wait_network
apt install $INTERACTIVE \
    casper \
    discover \
    laptop-detect \
    os-prober \
    keyutils \
    --no-install-recommends
judge "Install live-boot"

# Update package list before searching
print_ok "Updating package list..."
apt update
judge "Update package list"

# Detect architecture for kernel package
ARCH=$(dpkg --print-architecture)
TARGET_KERNEL_PACKAGE=""

if [ "$ARCH" = "amd64" ]; then
    # For amd64, try HWE kernel first, then fallback to generic
    print_ok "Detecting kernel package for amd64..."
    TARGET_KERNEL_PACKAGE=$(apt-cache search --names-only '^linux-generic-hwe-' 2>/dev/null | awk '{print $1}' | sort -V | tail -1)
    
    # If HWE not found, try regular generic
    if [ -z "$TARGET_KERNEL_PACKAGE" ]; then
        print_warn "HWE kernel not found, trying generic kernel..."
        TARGET_KERNEL_PACKAGE=$(apt-cache search --names-only '^linux-generic$' 2>/dev/null | awk '{print $1}' | head -1)
    fi
elif [ "$ARCH" = "arm64" ]; then
    # For arm64, use linux-generic
    print_ok "Detecting kernel package for arm64..."
    TARGET_KERNEL_PACKAGE=$(apt-cache search --names-only '^linux-generic$' 2>/dev/null | awk '{print $1}' | head -1)
fi

# Final fallback: try to find any linux-generic package
if [ -z "$TARGET_KERNEL_PACKAGE" ]; then
    print_warn "Specific kernel package not found, trying fallback..."
    TARGET_KERNEL_PACKAGE=$(apt-cache search --names-only 'linux-generic' 2>/dev/null | awk '{print $1}' | head -1)
fi

# Verify we found a kernel package
if [ -z "$TARGET_KERNEL_PACKAGE" ]; then
    print_error "Failed to detect kernel package for architecture $ARCH"
    print_error "Available kernel packages:"
    apt-cache search --names-only 'linux-generic' 2>/dev/null | head -10 || true
    exit 1
fi

print_ok "Installing kernel package $TARGET_KERNEL_PACKAGE for $ARCH..."
if [ "$ARCH" = "amd64" ]; then
    apt install $INTERACTIVE \
        thermald \
        $TARGET_KERNEL_PACKAGE \
        --no-install-recommends
else
    apt install $INTERACTIVE \
        $TARGET_KERNEL_PACKAGE \
        --no-install-recommends
fi
judge "Install kernel package"

# Verify kernel files were created
print_ok "Verifying kernel installation..."
if ! ls /boot/vmlinuz-* >/dev/null 2>&1; then
    print_error "Kernel files (vmlinuz) not found in /boot/"
    print_error "Contents of /boot/:"
    ls -la /boot/ || true
    exit 1
fi

if ! ls /boot/initrd.img-* >/dev/null 2>&1; then
    print_error "Initrd files not found in /boot/"
    print_error "Contents of /boot/:"
    ls -la /boot/ || true
    exit 1
fi

print_ok "Kernel installation verified successfully"
KERNEL_COUNT=$(ls -1 /boot/vmlinuz-* 2>/dev/null | wc -l)
print_ok "Found $KERNEL_COUNT kernel file(s) in /boot/"
