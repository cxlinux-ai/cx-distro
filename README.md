# CX Distro

**Debian-based Distribution Engineering for CX Linux**

[![License](https://img.shields.io/badge/license-BSL%201.1-orange.svg)](LICENSE)
[![Debian](https://img.shields.io/badge/base-Debian%2013%20trixie-A81D33.svg)](https://debian.org)
[![Build](https://img.shields.io/github/actions/workflow/status/cxlinux-ai/cx-distro/build-iso.yml?branch=main)](https://github.com/cxlinux-ai/cx-distro/actions)

## Overview

`cx-distro` handles everything related to building and distributing CX Linux as a Debian-based operating system. This includes ISO generation, package repository management, automated installation, and supply-chain security.

**CX Linux** is an AI-native operating system that translates natural language commands into Linux operations, eliminating traditional documentation complexity for server management.

## Quick Start

### Build ISO (Debian/Ubuntu host required)

```bash
# Clone repository
git clone https://github.com/cxlinux-ai/cortex-distro.git
cd cx-distro

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
<<<<<<< HEAD
├── cx-linux-0.1.0-amd64-offline.iso      # Bootable ISO
├── cx-linux-0.1.0-amd64-offline.iso.sha256
├── packages/
│   ├── cx-archive-keyring_*.deb
│   ├── cx-core_*.deb
│   └── cx-full_*.deb
└── sbom/
    ├── cx-linux-0.1.0.cdx.json           # CycloneDX SBOM
    └── cx-linux-0.1.0.spdx.json          # SPDX SBOM
=======
├── cortex-linux-0.1.0-amd64.iso           # Bootable ISO
├── cortex-linux-0.1.0-amd64.iso.sha256
└── sbom/
    ├── cortex-linux-0.1.0.cdx.json        # CycloneDX SBOM
    └── cortex-linux-0.1.0.spdx.json       # SPDX SBOM
>>>>>>> aa34a92 (Refactor Cortex Linux documentation and build scripts)
```

## Architecture

```
cx-distro/
├── iso/                        # ISO build configuration
│   ├── live-build/             # Debian live-build configs
│   │   ├── auto/               # Build automation scripts
│   │   └── config/             # Package lists, hooks, includes
│   ├── preseed/                # Automated installation preseeds
│   └── provisioning/           # First-boot setup scripts
├── packages/                   # Debian package definitions
<<<<<<< HEAD
<<<<<<< HEAD
│   ├── cx-archive-keyring/ # GPG keyring package
│   ├── cx-core/            # Minimal installation meta-package
│   └── cx-full/            # Full installation meta-package
=======
│   └── cortex-branding/        # Branding package
>>>>>>> aa34a92 (Refactor Cortex Linux documentation and build scripts)
=======
│   └── cortex-branding/        # Branding package (self-contained)
│       ├── source/             # Master logo images
│       ├── Makefile            # Asset generator
│       └── debian/             # Package build files
>>>>>>> 85a1b65 (Refactor Cortex Linux branding package and update asset management)
├── repository/                 # APT repository tooling
│   └── scripts/                # repo-manage.sh
├── sbom/                       # SBOM generation (CycloneDX/SPDX)
├── docs/                       # Documentation
│   └── branding/               # Brand guidelines and asset docs
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
<<<<<<< HEAD
| **Meta-packages** | cx-core (minimal), cx-full (complete) |
=======
>>>>>>> aa34a92 (Refactor Cortex Linux documentation and build scripts)
| **First-boot** | Preseed automation and idempotent provisioning |
| **SBOM** | Software Bill of Materials (CycloneDX/SPDX) |

## Included Software

<<<<<<< HEAD
### cx-core (Minimal)
=======
The Cortex Linux ISO includes:
>>>>>>> aa34a92 (Refactor Cortex Linux documentation and build scripts)
- Base system with Python 3.11+
- GNOME desktop environment
- Security sandbox (Firejail, AppArmor)
<<<<<<< HEAD
- SSH server
- CX package manager dependencies

### cx-full (Recommended)
Everything in cx-core plus:
- Docker and container tools
=======
- Container runtime (Docker, Podman)
>>>>>>> aa34a92 (Refactor Cortex Linux documentation and build scripts)
- Network security (nftables, fail2ban)
- Monitoring (Prometheus node exporter)
- Web server (nginx) and TLS (certbot)
- GPU support prerequisites (NVIDIA, AMD)
- Modern CLI tools (htop, btop, fzf, ripgrep, bat)
- AI/ML prerequisites (numpy, scipy, pandas)

## Automated Installation

CX Linux supports fully unattended installation via preseed:

```bash
# Boot parameter for automated install
preseed/file=/cdrom/preseed/cx.preseed
```

### Preseed Features
- UEFI and BIOS support
- LVM partitioning (default)
- Optional LUKS encryption
- SSH key injection
- Admin user creation
- CX repository configuration

## APT Repository

CX uses a signed APT repository with deb822 format:

```
# /etc/apt/sources.list.d/cx.sources
Types: deb
URIs: https://repo.cxlinux-ai.com/apt
Suites: cx cx-updates cx-security
Components: main
Signed-By: /usr/share/keyrings/cx-archive-keyring.gpg
```

### Repository Management

```bash
# Initialize repository
./repository/scripts/repo-manage.sh init

# Add package
<<<<<<< HEAD
./repository/scripts/repo-manage.sh add packages/cx-core_0.1.0-1_all.deb
=======
./repository/scripts/repo-manage.sh add packages/cortex-branding_1.0.0_all.deb
>>>>>>> aa34a92 (Refactor Cortex Linux documentation and build scripts)

# Publish (sign and generate metadata)
CX_GPG_KEY_ID=ABCD1234 ./repository/scripts/repo-manage.sh publish

# Create snapshot
./repository/scripts/repo-manage.sh snapshot

# Export for offline use
./repository/scripts/repo-manage.sh export cx-offline-repo
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
<<<<<<< HEAD
make iso            # Build full offline ISO
make iso-netinst    # Build minimal network installer
make package        # Build all Debian packages
make package PKG=cx-core  # Build specific package
=======
make iso            # Build ISO
make iso ARCH=arm64 # Build ARM64 ISO
>>>>>>> aa34a92 (Refactor Cortex Linux documentation and build scripts)
make sbom           # Generate SBOM
make test           # Run verification tests
make clean          # Remove build artifacts
make install-deps   # Install build dependencies
```

## Topics Covered

This repository implements 9 major topics from the CX Linux planning:

- [x] Automated installation and first-boot provisioning
- [x] CX package repository and apt trust model
- [x] Debian base selection and compatibility contract
- [ ] Debian packaging strategy for CX components
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

- [cortex](https://github.com/cxlinux-ai/cortex) - AI-powered package manager CLI
- [website](https://github.com/cxlinux-ai/website) - cxlinux-ai.com

## License

BSL 1.1 - See [LICENSE](LICENSE)

## Support

- Documentation: https://cxlinux-ai.com/docs
- Issues: https://github.com/cxlinux-ai/cx-distro/issues
- Discord: https://discord.gg/cxlinux-ai

---

**Copyright 2025 AI Venture Holdings LLC**
