# CX Linux Ubuntu 24.04 Quick Start

**One-command ISO build for Ubuntu 24.04 LTS based CX Linux**

## Prerequisites

Ubuntu 22.04+ or Debian 12+ build host with sudo access:

```bash
# Install build dependencies
sudo apt-get update && sudo apt-get install -y \
    live-build debootstrap squashfs-tools xorriso \
    dpkg-dev devscripts gnupg
```

## Build ISO

### Option 1: Makefile (Recommended)
```bash
git clone https://github.com/cxlinux-ai/cortex-distro.git
cd cortex-distro

# Install dependencies
make deps

# Build full offline ISO (~2-4GB)
make iso

# Build network installer (~500MB)
make iso-netinst
```

### Option 2: Build Script
```bash
# Full build with all features
sudo ./scripts/build.sh offline

# Network installer only
sudo ./scripts/build.sh netinst

# Clean build
sudo ./scripts/build.sh offline --clean
```

## Output

After successful build:
```
output/
├── cx-linux-0.1.0-amd64-offline.iso      # Bootable ISO
├── cx-linux-0.1.0-amd64-offline.iso.sha256
├── packages/                              # .deb packages
└── sbom/                                  # Software Bill of Materials
```

## Test ISO

### QEMU/KVM Test
```bash
# Boot ISO in VM
qemu-system-x86_64 \
    -m 4096 \
    -cdrom output/cx-linux-*.iso \
    -boot d \
    -enable-kvm \
    -netdev user,id=net0 \
    -device e1000,netdev=net0
```

### Verify Build
```bash
# Run verification tests
./tests/verify-ubuntu.sh

# Check ISO contents
./tests/verify-iso.sh output/cx-linux-*.iso
```

## Features

✅ **Ubuntu 24.04 LTS base** - Latest hardware support
✅ **Automatic GPU drivers** - NVIDIA & AMD detection
✅ **AI/ML optimized** - Python 3.12, CUDA support
✅ **Container ready** - Docker, Podman preinstalled
✅ **Security hardened** - AppArmor, UFW, auto-updates
✅ **Zero-config install** - Automated provisioning

## Installation Options

### Interactive Install
Boot from ISO and follow graphical installer.

### Automated Install (Preseed)
```bash
# Boot with kernel parameters:
preseed/file=/cdrom/preseed/cx.preseed
```

### Network Install
```bash
# Download preseed from web:
preseed/url=https://cxlinux-ai.com/preseed/cx.preseed
```

## First Boot

System automatically configures:
- GPU drivers (NVIDIA/AMD detection)
- Network via Netplan
- SSH with key authentication
- UFW firewall
- CX package manager
- Security updates

## Quick Commands

```bash
# Check system status
cx status

# Install packages with AI assistance
cx install docker nginx python3-pip

# Configure GPU for AI workloads
cx gpu setup

# Show system info
cx info
```

## Troubleshooting

**Build fails**: Check `build/build-offline.log` for errors
**Missing packages**: Verify Ubuntu mirror connectivity
**Permission denied**: Ensure sudo access for live-build
**Low disk space**: Need 10GB+ free for offline build

**Need help?**
- Docs: https://cxlinux-ai.com/docs
- Issues: https://github.com/cxlinux-ai/cx-distro/issues
- Discord: https://discord.gg/cxlinux-ai

---
**Built for Ubuntu 24.04 LTS • AI-Native Linux Distribution**