# Cortex Distro

**Debian-based Distribution Engineering for Cortex Linux**

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Debian](https://img.shields.io/badge/base-Debian%2013%20trixie-A81D33.svg)](https://debian.org)
[![Build](https://img.shields.io/github/actions/workflow/status/cortexlinux/cortex-distro/build-iso.yml?branch=main)](https://github.com/cortexlinux/cortex-distro/actions)

## Overview

`cortex-distro` handles everything related to building and distributing Cortex Linux as a Debian-based operating system. This includes ISO generation, package repository management, automated installation, and supply-chain security.

**Cortex Linux** is an AI-native operating system that translates natural language commands into Linux operations, eliminating traditional documentation complexity for server management.

## Quick Start

### Build ISO (Debian/Ubuntu host required)

```bash
# Clone repository
git clone https://github.com/cortexlinux/cortex-distro.git
cd cortex-distro

# Install dependencies
sudo ./scripts/install-deps.sh

# Build ISO
make iso

# Build for ARM64
make iso ARCH=arm64
```

### Output

After a successful build:
```
output/
├── cortex-linux-0.1.0-amd64.iso           # Bootable ISO
├── cortex-linux-0.1.0-amd64.iso.sha256
└── sbom/
    ├── cortex-linux-0.1.0.cdx.json        # CycloneDX SBOM
    └── cortex-linux-0.1.0.spdx.json       # SPDX SBOM
```

## Architecture

```
cortex-distro/
├── iso/                        # ISO build configuration
│   ├── live-build/             # Debian live-build configs
│   │   ├── auto/               # Build automation scripts
│   │   └── config/             # Package lists, hooks, includes
│   ├── preseed/                # Automated installation preseeds
│   └── provisioning/           # First-boot setup scripts
├── packages/                   # Debian package definitions
│   └── cortex-branding/        # Branding package
├── repository/                 # APT repository tooling
│   └── scripts/                # repo-manage.sh
├── sbom/                       # SBOM generation (CycloneDX/SPDX)
├── branding/                   # Plymouth theme, wallpapers
├── scripts/                    # Build automation
│   ├── build.sh                # Master build script
│   └── install-deps.sh         # Dependency installer
├── tests/                      # Verification tests
│   ├── verify-iso.sh
│   ├── verify-packages.sh
│   └── verify-preseed.sh
├── .github/workflows/          # CI/CD pipelines
├── Makefile                    # Build targets
└── README.md
```

## Key Components

| Component | Description |
|-----------|-------------|
| **ISO Builder** | Reproducible ISO image pipeline using Debian live-build |
| **APT Repository** | Signed package repository with GPG key management |
| **First-boot** | Preseed automation and idempotent provisioning |
| **SBOM** | Software Bill of Materials (CycloneDX/SPDX) |

## Included Software

The Cortex Linux ISO includes:
- Base system with Python 3.11+
- GNOME desktop environment
- Security sandbox (Firejail, AppArmor)
- Container runtime (Docker, Podman)
- Network security (nftables, fail2ban)
- Monitoring (Prometheus node exporter)
- Web server (nginx) and TLS (certbot)
- GPU support prerequisites (NVIDIA, AMD)
- Modern CLI tools (htop, btop, fzf, ripgrep, bat)
- AI/ML prerequisites (numpy, scipy, pandas)

## Automated Installation

Cortex Linux supports fully unattended installation via preseed:

```bash
# Boot parameter for automated install
preseed/file=/cdrom/preseed/cortex.preseed
```

### Preseed Features
- UEFI and BIOS support
- LVM partitioning (default)
- Optional LUKS encryption
- SSH key injection
- Admin user creation
- Cortex repository configuration

## APT Repository

Cortex uses a signed APT repository with deb822 format:

```
# /etc/apt/sources.list.d/cortex.sources
Types: deb
URIs: https://repo.cortexlinux.com/apt
Suites: cortex cortex-updates cortex-security
Components: main
Signed-By: /usr/share/keyrings/cortex-archive-keyring.gpg
```

### Repository Management

```bash
# Initialize repository
./repository/scripts/repo-manage.sh init

# Add package
./repository/scripts/repo-manage.sh add packages/cortex-branding_1.0.0_all.deb

# Publish (sign and generate metadata)
CORTEX_GPG_KEY_ID=ABCD1234 ./repository/scripts/repo-manage.sh publish

# Create snapshot
./repository/scripts/repo-manage.sh snapshot

# Export for offline use
./repository/scripts/repo-manage.sh export cortex-offline-repo
```

## Security

### Supply Chain
- Signed ISO images (SHA256/SHA512)
- Signed APT repository (GPG)
- SBOM generation (CycloneDX, SPDX)
- Reproducible builds (goal)

### System Hardening
- AppArmor profiles
- Firejail sandboxing
- Secure sysctl defaults
- SSH hardening
- nftables firewall

## Build Targets

```bash
make help           # Show all targets
make iso            # Build ISO
make iso ARCH=arm64 # Build ARM64 ISO
make sbom           # Generate SBOM
make test           # Run verification tests
make clean          # Remove build artifacts
make install-deps   # Install build dependencies
```

## Topics Covered

This repository implements 9 major topics from the Cortex Linux planning:

- [x] Automated installation and first-boot provisioning
- [x] Cortex package repository and apt trust model
- [x] Debian base selection and compatibility contract
- [ ] Debian packaging strategy for Cortex components
- [ ] GPU driver enablement and packaging (NVIDIA/AMD)
- [x] ISO image build system (live-build)
- [ ] Kernel, firmware, and hardware enablement plan
- [x] Reproducible builds, artifact signing, and SBOM outputs
- [ ] Upgrade, rollback, and version pinning

## Requirements

### Build Host
- Debian 12+ or Ubuntu 24.04+
- 10GB+ free disk space
- Internet connection (for package downloads)
- Root/sudo access

### Target Hardware
- x86_64 (amd64) or ARM64 architecture
- UEFI or Legacy BIOS
- 2GB+ RAM (4GB+ recommended)
- 20GB+ storage

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run tests: `make test`
5. Submit PR

## Related Repositories

- [cortex](https://github.com/cortexlinux/cortex) - AI-powered package manager CLI
- [website](https://github.com/cortexlinux/website) - cortexlinux.com

## License

Apache 2.0 - See [LICENSE](LICENSE)

## Support

- Documentation: https://cortexlinux.com/docs
- Issues: https://github.com/cortexlinux/cortex-distro/issues
- Discord: https://discord.gg/cortexlinux

---

**Copyright 2025 AI Venture Holdings LLC**
