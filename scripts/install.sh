#!/bin/bash
# CX Linux Installer
# Downloads and installs CX Linux packages from GitHub Releases
# Usage: curl -fsSL https://raw.githubusercontent.com/cxlinux-ai/cx-distro/main/scripts/install.sh | bash

set -e

REPO="cxlinux-ai/cx-distro"
RELEASE_API="https://api.github.com/repos/${REPO}/releases/latest"

echo "╔═══════════════════════════════════════════════════╗"
echo "║           CX Linux Installer                      ║"
echo "║   AI-Native Linux Distribution                    ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Detect architecture
ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
case "$ARCH" in
    amd64|x86_64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "→ Detected architecture: $ARCH"
echo "→ Fetching latest release..."

# Get latest release info
RELEASE_INFO=$(curl -fsSL "$RELEASE_API")
TAG=$(echo "$RELEASE_INFO" | grep -o '"tag_name": "[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TAG" ]; then
    echo "ERROR: Could not fetch release information"
    echo "Please check https://github.com/${REPO}/releases"
    exit 1
fi

echo "→ Latest version: $TAG"

# Download URLs
BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
PACKAGES=("cx-archive-keyring" "cx-core")

# Create temp directory
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "→ Downloading packages..."

for pkg in "${PACKAGES[@]}"; do
    # Find the exact filename from release assets
    FILENAME=$(echo "$RELEASE_INFO" | grep -o "\"name\": \"${pkg}_[^\"]*\.deb\"" | head -1 | cut -d'"' -f4)
    
    if [ -z "$FILENAME" ]; then
        echo "  ⚠ Package $pkg not found in release, skipping..."
        continue
    fi
    
    echo "  ↓ $FILENAME"
    curl -fsSL -o "$TMPDIR/$FILENAME" "$BASE_URL/$FILENAME"
done

echo "→ Installing packages..."

# Install keyring first
if ls "$TMPDIR"/cx-archive-keyring*.deb 1>/dev/null 2>&1; then
    dpkg -i "$TMPDIR"/cx-archive-keyring*.deb
fi

# Install core package
if ls "$TMPDIR"/cx-core*.deb 1>/dev/null 2>&1; then
    dpkg -i "$TMPDIR"/cx-core*.deb || apt-get install -f -y
fi

echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║   ✓ CX Linux installed successfully!              ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""
echo "Try: cx ask 'what is my system info'"
echo ""
