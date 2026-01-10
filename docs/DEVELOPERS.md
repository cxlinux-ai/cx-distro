# Cortex Linux Developer Guide

Guide for contributing to Cortex Linux distribution development.

## Development Environment Setup

### Prerequisites

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install live-build gpg python3 shellcheck debootstrap

# Verify live-build version (need >= 1:20210814)
dpkg -l live-build
```

### Clone Repository

```bash
git clone https://github.com/cortexlinux/cortex-distro.git
cd cortex-distro
```

### Verify Setup

```bash
make check-deps
```

## Building ISOs

### Quick Build

```bash
# Build full desktop ISO (amd64)
make iso-full

# Build minimal ISO
make iso-core

# Build security-hardened ISO
make iso-secops
```

### ARM64 Builds

```bash
make iso-arm64-full
# or
ARCH=arm64 make iso-full
```

### Output Location

ISOs are created in `output/`:
```
output/cortex-linux-full-20250109-amd64.iso
output/cortex-linux-core-20250109-amd64.iso
output/cortex-linux-secops-20250109-amd64.iso
```

## Project Structure

```
cortex-distro/
├── Makefile                 # Build orchestration
├── iso/
│   ├── live-build/          # Debian live-build configuration
│   │   └── config/
│   │       ├── package-lists/   # Packages included in ISO
│   │       ├── hooks/           # Build-time scripts
│   │       ├── includes.chroot/ # Files copied into live filesystem
│   │       ├── includes.binary/ # Files on ISO root
│   │       └── bootloaders/     # GRUB configuration
│   ├── preseed/             # Automated installation configs
│   │   ├── profiles/        # core, full, secops profiles
│   │   └── partitioning/    # Disk layout templates
│   └── provisioning/        # First-boot setup scripts
├── packages/                # Debian package definitions
│   ├── cortex-branding/     # Branding package
│   ├── cortex-core/         # Core meta-package
│   ├── cortex-full/         # Full meta-package
│   └── cortex-secops/       # SecOps meta-package
├── branding/                # Visual assets
│   ├── plymouth/            # Boot splash
│   ├── grub/                # Bootloader theme
│   ├── wallpapers/          # Desktop backgrounds
│   └── gdm/                 # Login screen
└── docs/                    # Documentation
```

## Key Files

| File | Purpose |
|------|---------|
| `Makefile` | Build targets and orchestration |
| `iso/live-build/config/package-lists/live.list.chroot` | Packages in live ISO |
| `iso/live-build/config/hooks/live/*.hook.chroot` | Build-time customization |
| `iso/preseed/profiles/*.preseed` | Installation automation |
| `iso/provisioning/first-boot.sh` | Post-install setup |

## Adding Packages to ISO

Edit `iso/live-build/config/package-lists/live.list.chroot`:

```bash
# Add your package (one per line)
your-package-name
```

## Creating Build Hooks

Hooks run during ISO build. Create in `iso/live-build/config/hooks/live/`:

```bash
# Example: 50-custom.hook.chroot
#!/bin/bash
set -e
echo "Running custom hook..."
# Your customization here
```

Make executable: `chmod +x 50-custom.hook.chroot`

Hook naming:
- `XX-name.hook.chroot` - Runs in chroot (live filesystem)
- `XX-name.hook.binary` - Runs on ISO filesystem
- Lower numbers run first (50 before 99)

## Testing

### Validate Configuration

```bash
make validate          # Run all checks
make preseed-check     # Validate preseed syntax
make provision-check   # Validate provisioning scripts
make lint              # Run shellcheck on scripts
```

### Test ISO in VM

```bash
# QEMU (amd64)
qemu-system-x86_64 -m 4G -cdrom output/cortex-linux-full-*.iso -boot d

# QEMU (arm64)
qemu-system-aarch64 -M virt -cpu cortex-a72 -m 4G -cdrom output/cortex-linux-full-*-arm64.iso
```

### Test in VirtualBox/UTM

1. Create new VM (Debian 64-bit)
2. Allocate 4GB RAM, 20GB disk
3. Mount ISO as optical drive
4. Boot and test installation

## Building Packages

### Build Branding Package

```bash
make branding-package
# Output: output/cortex-branding_1.0.0_all.deb
```

### Package Structure

```
packages/cortex-example/
└── DEBIAN/
    ├── control      # Package metadata
    ├── postinst     # Post-install script (optional)
    └── prerm        # Pre-remove script (optional)
```

## Commit Guidelines

Follow conventional commits:
```
feat: add new feature
fix: bug fix
docs: documentation
refactor: code refactoring
test: add tests
chore: maintenance
```

Example:
```bash
git commit -m "feat: add cortex-llm package support"
```

## Troubleshooting

### Build fails with permission error

```bash
# live-build requires sudo for chroot operations
sudo lb build
```

### Hooks not running

1. Check hook is executable: `chmod +x your-hook.hook.chroot`
2. Check naming convention: `XX-name.hook.chroot`
3. Check syntax: `bash -n your-hook.hook.chroot`

### Package not found in ISO

1. Verify package in `live.list.chroot`
2. Check package exists in Debian repos: `apt-cache search package-name`
3. Run `make clean` and rebuild

## Resources

- [Debian Live Manual](https://live-team.pages.debian.net/live-manual/)
- [Preseed Documentation](https://wiki.debian.org/DebianInstaller/Preseed)
- [Debian Packaging Guide](https://www.debian.org/doc/manuals/maint-guide/)
