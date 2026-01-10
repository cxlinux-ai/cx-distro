# Cortex Linux Quick Start Guide

Get Cortex Linux tools running in 2 minutes.

## Option 1: Add Cortex Repository to Existing Debian/Ubuntu

```bash
# Add GPG key
curl -fsSL https://apt.cortexlinux.com/keys/cortex-linux.gpg.asc | sudo gpg --dearmor -o /usr/share/keyrings/cortex-linux.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/cortex-linux.gpg] https://apt.cortexlinux.com stable main" | sudo tee /etc/apt/sources.list.d/cortex-linux.list

# Update and install
sudo apt update
sudo apt install cortex-core
```

This installs:
- `cortex-upgrade` - Safe system upgrades with snapshot rollback
- `cortex-gpu` - GPU detection and driver setup
- `cortex-verify` - System integrity verification

## Option 2: Install Full Desktop

```bash
sudo apt install cortex-full
```

Adds GNOME desktop, dev tools (Python, Node, Go, Rust, Docker), and productivity apps.

## Option 3: Security Operations Profile

```bash
sudo apt install cortex-secops
```

Adds security tools: AppArmor, auditd, AIDE, fail2ban, ClamAV, Lynis.

---

## System Requirements

| Profile | RAM | Disk | Use Case |
|---------|-----|------|----------|
| cortex-core | 512MB | 2GB | Servers, embedded, minimal |
| cortex-full | 4GB | 20GB | Workstations, development |
| cortex-secops | 4GB | 20GB | Security-critical systems |

## After Installation

### Check Cortex Tools

```bash
# System upgrade with rollback support
cortex-upgrade --check

# GPU detection and driver status
cortex-gpu status

# Verify system integrity
cortex-verify --quick
```

### First Steps

1. **Update system**: `sudo apt update && sudo apt upgrade`
2. **Configure firewall**: `sudo ufw enable`
3. **Set up SSH keys**: Add your public key to `~/.ssh/authorized_keys`

## Troubleshooting

### Repository not found

```bash
# Verify GPG key
gpg --show-keys /usr/share/keyrings/cortex-linux.gpg

# Check sources list
cat /etc/apt/sources.list.d/cortex-linux.list
```

### Package conflicts

```bash
# Check held packages
apt-mark showhold

# Fix broken packages
sudo apt --fix-broken install
```

## Next Steps

- [Automated Installation Guide](automated-installation.md) - Full ISO installation
- [Building ISOs](DEVELOPERS.md) - Build custom Cortex Linux ISOs
