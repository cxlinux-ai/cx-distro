#!/bin/bash
# Cortex Linux Build Dependencies Installer
# Copyright 2025 AI Venture Holdings LLC
# SPDX-License-Identifier: Apache-2.0

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

<<<<<<< HEAD
# Architecture detection: use ARCH env var if set, otherwise detect from system
ARCH="${ARCH:-$(dpkg --print-architecture 2>/dev/null || echo amd64)}"
=======
ARCH=$(dpkg --print-architecture)
>>>>>>> 3b68a92 (Refactor Makefile and GitHub Actions workflow for streamlined ISO build process)

log "Installing Cortex Linux build dependencies for ${ARCH}..."

# Update package lists
apt-get update

# Common packages for all architectures
COMMON_PACKAGES=(
<<<<<<< HEAD
    binutils
=======
    git
    make
    sudo
    live-build
>>>>>>> 3b68a92 (Refactor Makefile and GitHub Actions workflow for streamlined ISO build process)
    debootstrap
    squashfs-tools
    xorriso
    isolinux
    syslinux-efi
    mtools
    dosfstools
<<<<<<< HEAD
    grub2-common
=======
>>>>>>> 3b68a92 (Refactor Makefile and GitHub Actions workflow for streamlined ISO build process)
    imagemagick
    gnupg
    python3
    shellcheck
    dpkg-dev
<<<<<<< HEAD
    lz4
    git
    make
    sudo
=======
>>>>>>> 3b68a92 (Refactor Makefile and GitHub Actions workflow for streamlined ISO build process)
)

log "Installing common packages..."
apt-get install -y "${COMMON_PACKAGES[@]}"

# Architecture-specific bootloader packages
if [ "$ARCH" = "amd64" ]; then
    log "Installing amd64-specific bootloader packages..."
    apt-get install -y grub-pc-bin grub-efi-amd64-bin
elif [ "$ARCH" = "arm64" ]; then
    log "Installing arm64-specific bootloader packages..."
    apt-get install -y grub-efi-arm64-bin
else
    warn "Unknown architecture: ${ARCH}"
    warn "You may need to install bootloader packages manually"
<<<<<<< HEAD
    warn "Supported architectures: amd64, arm64"
fi

log "All dependencies installed successfully for ${ARCH}!"
=======
fi

log "All dependencies installed successfully!"
>>>>>>> 3b68a92 (Refactor Makefile and GitHub Actions workflow for streamlined ISO build process)
