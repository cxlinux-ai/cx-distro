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

# Detect architecture for kernel package
ARCH=$(dpkg --print-architecture)
if [ "$ARCH" = "amd64" ]; then
    # For amd64, use the HWE kernel: linux-generic-hwe-*
    TARGET_KERNEL_PACKAGE=$(apt search linux-generic-hwe-* 2>/dev/null | awk -F'/' '/linux-generic-hwe-/ {print $1}' | sort | head -n 1)
elif [ "$ARCH" = "arm64" ]; then
    # For arm64, HWE kernel is generally not provided; use linux-generic instead
    TARGET_KERNEL_PACKAGE=$(apt search linux-generic 2>/dev/null | awk -F'/' '/^linux-generic / {print $1}' | head -n 1)
fi

if [ -z "$TARGET_KERNEL_PACKAGE" ]; then
    # Fallback to generic kernel if nothing found above
    TARGET_KERNEL_PACKAGE=$(apt search linux-generic 2>/dev/null | awk -F'/' '/^linux-generic / {print $1}' | head -n 1)
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
