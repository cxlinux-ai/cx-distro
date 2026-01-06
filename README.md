# Cortex Distro

**Debian-based Distribution Engineering for Cortex Linux**

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Debian](https://img.shields.io/badge/base-Debian%2012-A81D33.svg)](https://debian.org)

## Overview

`cortex-distro` handles everything related to building and distributing Cortex Linux as a Debian-based operating system. This includes ISO generation, package repository management, and supply-chain security.

## Key Components

| Component | Description |
|-----------|-------------|
| **ISO Builder** | Reproducible ISO image pipeline using live-build |
| **APT Repository** | Signed package repository with GPG key management |
| **Meta-packages** | cortex-core, cortex-full, cortex-secops bundles |
| **First-boot** | Preseed automation and provisioning scripts |
| **SBOM** | Software Bill of Materials generation (SPDX/CycloneDX) |

## Architecture

```
cortex-distro/
├── iso/                    # ISO build configuration
│   ├── live-build/         # Debian live-build configs
│   └── preseed/            # Automated installation answers
├── packages/               # Meta-package definitions
│   ├── cortex-core/        # Minimal installation
│   ├── cortex-full/        # Full installation
│   └── cortex-secops/      # Security-focused installation
├── repository/             # APT repository tooling
│   ├── keys/               # GPG signing keys (gitignored)
│   └── scripts/            # Repository management
├── sbom/                   # SBOM generation tools
└── tests/                  # Build verification tests
```

## Topics (from Planning)

This repository covers 9 major topics with 92 decisions and 99 tasks:

- [ ] Automated installation and first-boot provisioning
- [ ] Cortex package repository and apt trust model
- [ ] Debian base selection and compatibility contract
- [ ] Debian packaging strategy for Cortex components
- [ ] GPU driver enablement and packaging (NVIDIA/AMD)
- [ ] ISO image build system (live-build vs debian-installer)
- [ ] Kernel, firmware, and hardware enablement plan
- [ ] Reproducible builds, artifact signing, and SBOM outputs
- [ ] Upgrade, rollback, and version pinning

## Quick Start

```bash
# Build ISO (requires Debian/Ubuntu host)
make iso

# Build specific meta-package
make package PKG=cortex-core

# Generate SBOM for latest build
make sbom
```

## Dependencies

- Debian 12+ or Ubuntu 24.04+ build host
- live-build package
- GPG for signing
- Python 3.11+ for tooling

## Related Repositories

- [cortex-cli](https://github.com/cortexlinux/cortex-cli) - AI-powered shell
- [cortex-llm](https://github.com/cortexlinux/cortex-llm) - Local LLM runtime
- [cortex-security](https://github.com/cortexlinux/cortex-security) - Hardening profiles

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Apache 2.0 - See [LICENSE](LICENSE)
