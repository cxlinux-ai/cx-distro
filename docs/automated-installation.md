# Automated Installation Guide

This guide covers unattended installation of Cortex Linux via PXE, ISO, or VM with preseed automation.

## Overview

Cortex Linux supports fully automated installation using Debian's preseed system. Three installation profiles are available:

| Profile | Use Case | Disk Layout | Encryption |
|---------|----------|-------------|------------|
| **core** | Servers, embedded, minimal | Simple (no LVM) | No |
| **full** | Workstations, development | LVM | No |
| **secops** | Security-focused, compliance | LVM + LUKS2 | Yes (FDE) |

## Quick Start

### Building an ISO

```bash
# Build full desktop ISO (default)
make iso

# Build specific profile
make iso-core      # Minimal server
make iso-full      # Full desktop
make iso-secops    # Security-focused with FDE

# Build all profiles
make iso-all
```

### Boot Parameters

Append to kernel command line for automated installation:

```
preseed/file=/cdrom/preseed/profiles/cortex-{profile}.preseed
```

Replace `{profile}` with `core`, `full`, or `secops`.

## Installation Profiles

### Core Profile (`cortex-core`)

Minimal installation for servers and embedded systems.

**Features:**
- ~2GB disk footprint
- SSH server enabled
- UFW firewall configured
- No desktop environment
- Optimized for headless operation

**Partitioning:**
- 512MB EFI System Partition
- 1GB /boot (ext4)
- Remaining space / (ext4)

**Default packages:**
- sudo, openssh-server, curl
- ca-certificates, systemd-timesyncd

### Full Profile (`cortex-full`)

Complete installation with GNOME desktop and development tools.

**Features:**
- Full GNOME desktop environment
- Development toolchain (Python, Node.js, Go, Rust)
- Docker pre-configured
- Flatpak with Flathub
- Common productivity apps

**Partitioning (LVM):**
- 512MB EFI System Partition
- 1GB /boot (ext4)
- LVM Volume Group:
  - 32GB / (ext4)
  - 8GB swap
  - Remaining /home (ext4)

**Default packages:**
- Full core packages plus:
- build-essential, cmake, git
- docker.io, docker-compose
- nodejs, npm, golang, rustc
- firefox-esr, libreoffice, vlc

### SecOps Profile (`cortex-secops`)

Security-hardened installation with Full Disk Encryption.

**Features:**
- LUKS2 Full Disk Encryption
- AppArmor mandatory access control
- Audit daemon (auditd)
- AIDE integrity monitoring
- Kernel hardening (sysctl)
- ClamAV antivirus
- Automatic security updates

**Partitioning (Encrypted LVM):**
- 512MB EFI System Partition (unencrypted)
- 1GB /boot (ext4, unencrypted)
- LUKS2 encrypted container:
  - LVM Volume Group:
    - 32GB / (ext4)
    - 8GB swap
    - Remaining /home (ext4)

**Security packages:**
- apparmor, apparmor-profiles
- auditd, audispd-plugins
- aide, rkhunter, chkrootkit
- clamav, clamav-daemon
- lynis, libpam-pwquality
- unattended-upgrades

> **WARNING:** The SecOps profile uses a temporary FDE passphrase that MUST be changed at first boot. See [Changing FDE Passphrase](#changing-fde-passphrase).

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
6. Sets up fail2ban (full/secops)
7. Enables automatic updates (full/secops)
8. Applies security hardening (secops only)

### Provisioning States

The provisioning script is **idempotent** and **offline-capable**:

- **Idempotent:** Safe to run multiple times
- **Offline:** Core functionality works without network
- **Profile-aware:** Different actions per profile

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
    APPEND initrd=initrd.gz auto=true priority=critical preseed/url=http://server/preseed/cortex-full.preseed
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
    -cdrom cortex-linux-full-*.iso \
    -drive file=cortex.qcow2,format=qcow2 \
    -boot d \
    -append "auto=true priority=critical preseed/file=/cdrom/preseed/profiles/cortex-full.preseed"
```

### VirtualBox

1. Create new VM with Debian 64-bit template
2. Allocate at least 2GB RAM, 25GB disk
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

> The preseed uses a placeholder password hash. The first-boot script may require password change depending on profile.

### Changing FDE Passphrase

For SecOps profile, change the default passphrase immediately:

```bash
# List encrypted devices
lsblk

# Change passphrase (typically /dev/sda3 or /dev/nvme0n1p3)
sudo cryptsetup luksChangeKey /dev/sda3

# Verify
sudo cryptsetup luksDump /dev/sda3
```

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
# Check profile
cat /opt/cortex/provisioning/profile

# Check provisioning status
cat /opt/cortex/provisioning/.first-boot-complete

# View provisioning log
cat /var/log/cortex/first-boot.log

# Check services
systemctl status ssh
systemctl status ufw
systemctl status fail2ban  # full/secops only
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

### FDE Passphrase Forgotten

For SecOps profile with default passphrase:
- Default passphrase: `cortex-temp-fde-passphrase`

## Security Considerations

1. **Change default passphrase** immediately after SecOps installation
2. **Generate new SSH keys** - don't use the default host keys in production
3. **Update system** as soon as network is available
4. **Review firewall rules** and adjust for your environment
5. **Configure fail2ban** email notifications for production

## References

- [Debian Preseed Documentation](https://www.debian.org/releases/stable/amd64/apb.html)
- [live-build Manual](https://live-team.pages.debian.net/live-manual/)
- [Cortex Linux Security Guide](./security-guide.md)
