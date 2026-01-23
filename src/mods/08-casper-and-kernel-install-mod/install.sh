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
    TARGET_KERNEL_PACKAGE=$(apt search linux-generic-hwe-* 2>/dev/null | awk -F'/' '/linux-generic-hwe-/ {print $1}' | sort | head -n 1)
elif [ "$ARCH" = "arm64" ]; then
    TARGET_KERNEL_PACKAGE=$(apt search linux-generic-hwe-* 2>/dev/null | awk -F'/' '/linux-generic-hwe-/ {print $1}' | sort | head -n 1)
fi

if [ -z "$TARGET_KERNEL_PACKAGE" ]; then
    # Fallback to generic kernel if HWE not available
    TARGET_KERNEL_PACKAGE=$(apt search linux-generic 2>/dev/null | awk -F'/' '/^linux-generic / {print $1}' | head -n 1)
fi

print_ok "Installing kernel package $TARGET_KERNEL_PACKAGE for $ARCH..."
apt install $INTERACTIVE \
    thermald \
    $TARGET_KERNEL_PACKAGE \
    --no-install-recommends
judge "Install kernel package"
