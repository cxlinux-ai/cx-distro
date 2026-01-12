# Automated Installation Guide

This guide covers unattended installation of Cortex Linux via PXE, ISO, or VM with preseed automation.

## Overview

Cortex Linux supports fully automated installation using Debian's preseed system.

## Quick Start

### Building an ISO

```bash
# Build ISO (default)
make iso

# Build for ARM64
make iso ARCH=arm64
```

### Boot Parameters

Append to kernel command line for automated installation:

```
preseed/file=/cdrom/preseed/cortex.preseed
```

## Installation Features

The Cortex Linux ISO provides a complete system with:

- Full GNOME desktop environment
- Development toolchain (Python, Node.js, Go, Rust)
- Container runtime (Docker, Podman)
- GPU support (NVIDIA, AMD)
- Security tools (AppArmor, auditd, fail2ban)
- Monitoring (Prometheus node exporter)

**Partitioning (LVM):**
- 512MB EFI System Partition
- 1GB /boot (ext4)
- LVM Volume Group:
  - 32GB / (ext4)
  - 8GB swap
  - Remaining /home (ext4)

## Partitioning Options

### Standard Partitioning Recipes

Located in `iso/preseed/partitioning/`:

| Recipe | File | Description |
|--------|------|-------------|
| Simple UEFI | `simple-uefi.preseed` | GPT, no LVM, UEFI boot |
| Simple BIOS | `simple-bios.preseed` | MBR, no LVM, legacy boot |
| LVM UEFI | `lvm-uefi.preseed` | GPT with LVM, UEFI boot |
| FDE UEFI | `fde-uefi.preseed` | LUKS2 + LVM, UEFI boot |
| RAID1 UEFI | `raid1-uefi.preseed` | Software RAID1 + LVM |

### Custom Partitioning

To create custom partitioning, modify the `partman-auto/expert_recipe` in your preseed:

```
d-i partman-auto/expert_recipe string \
    custom-layout ::                   \
        512 512 512 fat32              \
            $primary{ }                \
            method{ efi } format{ }    \
        .                              \
        # Add more partitions...
```

## First-Boot Provisioning

After installation, the system runs a first-boot provisioning script that:

1. Generates unique machine-id
2. Configures sudo for the cortex user
3. Generates SSH host keys
4. Applies SSH hardening
5. Configures UFW firewall
6. Sets up fail2ban
7. Enables automatic updates

### Provisioning States

The provisioning script is **idempotent** and **offline-capable**:

- **Idempotent:** Safe to run multiple times
- **Offline:** Core functionality works without network

State is tracked in `/opt/cortex/provisioning/.first-boot-complete`.

### Logs

Provisioning logs are written to:
- `/var/log/cortex/first-boot.log`
- `journalctl -u cortex-first-boot`

## PXE Network Boot

### DHCP Configuration

Configure your DHCP server to provide:

```
filename "pxelinux.0";
next-server <TFTP_SERVER_IP>;
```

### TFTP Server Setup

```bash
# Install TFTP server
apt install tftpd-hpa

# Copy boot files
cp /path/to/cortex-iso/isolinux/* /srv/tftp/

# Create PXE config
mkdir -p /srv/tftp/pxelinux.cfg
```

### PXE Menu Entry

Create `/srv/tftp/pxelinux.cfg/default`:

```
DEFAULT cortex
LABEL cortex
    KERNEL linux
    APPEND initrd=initrd.gz auto=true priority=critical preseed/url=http://server/preseed/cortex.preseed
```

## VM Installation

### QEMU/KVM

```bash
# Create VM disk
qemu-img create -f qcow2 cortex.qcow2 50G

# Boot from ISO with preseed
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -cpu host \
    -cdrom cortex-linux-*.iso \
    -drive file=cortex.qcow2,format=qcow2 \
    -boot d \
    -append "auto=true priority=critical preseed/file=/cdrom/preseed/cortex.preseed"
```

### VirtualBox

1. Create new VM with Debian 64-bit template
2. Allocate at least 4GB RAM, 25GB disk
3. Mount Cortex ISO
4. Edit boot command to add preseed parameter

### VMware

1. Create new VM with Debian 12 guest OS
2. Mount Cortex ISO
3. Edit boot options in VM settings

## Post-Installation

### Default Credentials

- **Username:** cortex
- **Password:** Must be set at first login

> The preseed uses a placeholder password hash. The first-boot script may require password change.

### Adding SSH Keys

```bash
# As cortex user
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "your-public-key" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Verifying Installation

```bash
# Check provisioning status
cat /opt/cortex/provisioning/.first-boot-complete

# View provisioning log
cat /var/log/cortex/first-boot.log

# Check services
systemctl status ssh
systemctl status ufw
systemctl status fail2ban
```

## Troubleshooting

### Installation Hangs

1. Check preseed file syntax
2. Verify preseed file is accessible
3. Check boot parameters are correct

### Network Not Configured

Preseed defaults to DHCP. For static IP, add:

```
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/get_ipaddress string 192.168.1.100
d-i netcfg/get_netmask string 255.255.255.0
d-i netcfg/get_gateway string 192.168.1.1
d-i netcfg/get_nameservers string 8.8.8.8
```

### First-Boot Script Failed

1. Check logs: `journalctl -u cortex-first-boot`
2. Check script: `cat /var/log/cortex/first-boot.log`
3. Re-run manually: `sudo /opt/cortex/provisioning/first-boot.sh`

## Security Considerations

1. **Generate new SSH keys** - don't use the default host keys in production
2. **Update system** as soon as network is available
3. **Review firewall rules** and adjust for your environment
4. **Configure fail2ban** email notifications for production

## References

- [Debian Preseed Documentation](https://www.debian.org/releases/stable/amd64/apb.html)
- [live-build Manual](https://live-team.pages.debian.net/live-manual/)
