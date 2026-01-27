# CX-DISTRO - ISO Builder

## Purpose
Custom ISO builder for CX Linux distributions. Creates Debian/Ubuntu-based images with embedded LLM and NVIDIA variants.

## Repo Role in Ecosystem
- **Distribution builder** - creates installable ISOs
- Depends on: cx (pre-installed), cx-llm (for embedded models)
- Output: Bootable ISO images

## Key Features
- Debian/Ubuntu base system customization
- Embedded LLM model options (7B, 13B, 70B)
- NVIDIA driver variants (with CUDA)
- Automated installer with AI-guided setup
- Live USB support

## Key Directories
```
cx-distro/
├── base/           # Base system configuration
├── profiles/       # Distribution profiles
│   ├── minimal/    # CLI only
│   ├── desktop/    # Full desktop
│   └── server/     # Server variant
├── nvidia/         # NVIDIA-specific builds
├── scripts/        # Build scripts
└── iso/            # ISO generation
```

## Building an ISO
```bash
# Minimal CLI image
./build.sh --profile minimal --output cx-minimal.iso

# Desktop with embedded 7B model
./build.sh --profile desktop --llm 7b --output cx-desktop-7b.iso

# Server with NVIDIA drivers
./build.sh --profile server --nvidia --output cx-server-nvidia.iso
```

## Build Requirements
- Debian/Ubuntu host
- debootstrap
- squashfs-tools
- xorriso
- 50GB+ free space
- Root access

## Development Setup
```bash
# Install build dependencies
sudo apt install debootstrap squashfs-tools xorriso live-build

# Test build (small image)
./build.sh --profile minimal --test
```

## Configuration
Edit `profiles/{profile}/config.yaml`:
```yaml
base: ubuntu-24.04
packages:
  - cx
  - cx-cli
llm:
  model: mistral:7b
  embedded: true
```

## CI/CD
- GitHub Actions builds nightly ISOs
- Releases published to GitHub Releases
- SHA256 checksums for all images
