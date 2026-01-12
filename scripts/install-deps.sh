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

ARCH=$(dpkg --print-architecture)

log "Installing Cortex Linux build dependencies for ${ARCH}..."

# Update package lists
apt-get update

# Common packages for all architectures
COMMON_PACKAGES=(
    git
    make
    sudo
    live-build
    debootstrap
    squashfs-tools
    xorriso
    isolinux
    syslinux-efi
    mtools
    dosfstools
    imagemagick
    gnupg
    python3
    shellcheck
    dpkg-dev
    liblz4-tool
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
fi

log "All dependencies installed successfully!"
