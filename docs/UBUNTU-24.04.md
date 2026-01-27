# CX Linux Ubuntu 24.04 LTS Configuration

This document describes the Ubuntu 24.04 LTS specific configuration for CX Linux distribution builds.

## Overview

CX Linux is based on **Ubuntu 24.04 LTS (Noble Numbat)** to provide:
- Latest hardware support (GPUs, modern CPUs)
- Long-term stability (5 years support until 2029)
- Excellent AI/ML package ecosystem
- Native container support with Docker/Podman
- Modern kernel with latest security features

## Key Features

### 🚀 **AI-Optimized Stack**
- Python 3.12 with full development stack
- Automatic GPU driver detection and installation
- CUDA support via NVIDIA PPA
- Optimized BLAS/LAPACK for ML workloads

### 🔧 **Ubuntu 24.04 Enhancements**
- Snap package manager for latest applications
- Graphics drivers PPA for cutting-edge GPU support
- Netplan network configuration
- Systemd-resolved DNS management
- Automatic security updates

### 🛡️ **Security Hardening**
- AppArmor profiles enabled by default
- Unattended security updates
- Hardened SSH configuration
- UFW firewall with sensible defaults

## Build Configuration

### Base Distribution
```bash
# Ubuntu 24.04 LTS (Noble Numbat)
CODENAME="noble"
ARCH="amd64"

# Ubuntu package areas
--archive-areas "main restricted universe multiverse"

# Ubuntu mirrors
--parent-mirror-bootstrap "http://archive.ubuntu.com/ubuntu/"
--parent-mirror-chroot-security "http://security.ubuntu.com/ubuntu/"
```

### Package Repositories

The build automatically configures:

1. **Main Ubuntu repositories**:
   - main (officially supported packages)
   - restricted (proprietary drivers)
   - universe (community packages)
   - multiverse (non-free software)

2. **Security updates**:
   - security.ubuntu.com for critical patches
   - Automatic unattended upgrades for security fixes

3. **Graphics drivers PPA**:
   - ppa:graphics-drivers/ppa for latest NVIDIA/AMD drivers

## Build Process

### Prerequisites (Ubuntu/Debian host)

```bash
# Install build dependencies
sudo apt-get update
sudo apt-get install -y \
    live-build \
    debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-efi \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    dosfstools \
    dpkg-dev \
    devscripts \
    debhelper \
    fakeroot \
    gnupg
```

### Build Commands

```bash
# Build minimal network installer
./scripts/build.sh netinst

# Build full offline ISO
./scripts/build.sh offline

# Build with specific version
CX_VERSION=0.2.0 ./scripts/build.sh offline

# Clean build
./scripts/build.sh offline --clean
```

### Make Targets

```bash
make iso            # Full offline ISO
make iso-netinst     # Network installer
make package         # Build .deb packages only
make test            # Run verification tests
make clean           # Clean build artifacts
```

## ISO Variants

### Network Installer (~500MB)
- Minimal base system
- Downloads packages during installation
- Requires internet connection
- Fastest to download and burn

### Offline ISO (~2-4GB)
- Complete package pool included
- No internet required for installation
- Includes GPU drivers and AI tools
- Recommended for production deployment

## Installation Features

### Automated Installation (Preseed)

Boot with `preseed/file=/cdrom/preseed/cx.preseed` for:
- Unattended installation
- LVM partitioning with encryption support
- Automatic CX repository configuration
- SSH key injection
- Admin user creation

### First-Boot Provisioning

The system automatically configures on first boot:
- GPU driver detection and installation
- Network configuration via Netplan
- SSH hardening
- Firewall setup (UFW)
- CX package manager installation
- Security updates configuration

## Hardware Support

### GPU Support

**NVIDIA**:
- Automatic driver detection via `ubuntu-drivers`
- CUDA toolkit installation
- Proprietary drivers from graphics PPA

**AMD**:
- Mesa Vulkan drivers
- RadeonTop monitoring
- Open-source AMDGPU drivers

### CPU Architecture
- x86_64 (amd64) primary target
- UEFI and Legacy BIOS boot support
- Modern CPU features (AVX2, etc.)

## Package Management

### Core Packages (cx-core)
- Minimal server installation
- Python 3.12 runtime
- Basic security tools
- SSH server
- Hardware detection utilities

### Full Installation (cx-full)
- Everything in cx-core plus:
- Docker and Podman containers
- Development tools
- Monitoring stack (Prometheus, collectd)
- AI/ML prerequisites
- Modern CLI tools (ripgrep, fd, bat, etc.)

## Verification

Run the test suite to verify configuration:

```bash
./tests/verify-ubuntu.sh
```

This validates:
- ✅ Ubuntu 24.04 (noble) configuration
- ✅ Ubuntu package mirrors
- ✅ GPU driver support
- ✅ Hook scripts functionality
- ✅ Consistent CX Linux branding
- ✅ First-boot Ubuntu features

## Network Configuration

Uses **Netplan** (Ubuntu standard) with systemd-networkd:

```yaml
# /etc/netplan/01-cx-config.yaml
network:
  version: 2
  renderer: systemd-networkd
  ethernets:
    ens3:
      dhcp4: true
      dhcp6: true
      optional: true
```

## Security Configuration

### Automatic Updates
```bash
# Security-only automatic updates
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

### Firewall (UFW)
```bash
# Default UFW rules
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 8006/tcp  # CX console
```

### AppArmor
- Enforced profiles for all services
- Additional Ubuntu-specific profiles
- Custom CX profiles for AI workloads

## Development

### Testing Changes

```bash
# Build test ISO
make iso-netinst

# Verify in VM
qemu-system-x86_64 \
    -m 2048 \
    -cdrom output/cx-linux-*.iso \
    -boot d \
    -enable-kvm
```

### Adding Packages

1. Edit package lists: `iso/live-build/config/package-lists/`
2. Add custom hooks: `iso/live-build/config/hooks/live/`
3. Update first-boot: `iso/live-build/config/includes.chroot/usr/lib/cx/firstboot.sh`
4. Test with `./tests/verify-ubuntu.sh`

## Troubleshooting

### Common Issues

**Build fails with GPG errors**:
```bash
# Update Ubuntu keyring
sudo apt update
sudo apt install ubuntu-keyring
```

**Package conflicts**:
```bash
# Clean and rebuild
make clean
make iso
```

**Missing packages**:
```bash
# Check package availability
apt-cache search <package-name>
```

### Build Logs

Check detailed logs:
```bash
# Live-build logs
tail -f build/build-offline.log

# Hook script logs
grep "CX Linux" build/build-offline.log
```

## Support Matrix

| Component | Ubuntu 24.04 Support |
|-----------|----------------------|
| Kernel | 6.8+ (latest HWE) |
| Python | 3.12 (default) |
| Docker | 27.x (official) |
| NVIDIA | 550+ drivers |
| CUDA | 12.4+ toolkit |
| Mesa | 24.x (latest) |

## Migration from Debian

If migrating from Debian-based builds:

1. Update `CODENAME` from `bookworm` to `noble`
2. Replace Debian mirrors with Ubuntu mirrors
3. Update package names (firmware-* → linux-firmware)
4. Test with verification script

For questions or issues, see:
- GitHub Issues: https://github.com/cxlinux-ai/cx-distro/issues
- Documentation: https://cxlinux-ai.com/docs