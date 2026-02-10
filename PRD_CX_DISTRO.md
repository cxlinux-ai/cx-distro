# Product Requirements Document: CX Linux Distribution

**Document Version:** 1.0
**Date:** 2026-02-10
**Product:** CX Linux (formerly Cortex Linux)
**Repository:** cxlinux-ai/cx-distro
**Milestone Target:** v1.0 MVP by March 30, 2026 | v1.1 Phase 2 by June 29, 2026

---

## Table of Contents

1. [Product Vision & Overview](#1-product-vision--overview)
2. [Current State Assessment](#2-current-state-assessment)
3. [Work Stream 1: Package Pipeline (P0-Critical)](#3-work-stream-1-package-pipeline)
4. [Work Stream 2: ISO Build & Release (P0-Critical)](#4-work-stream-2-iso-build--release)
5. [Work Stream 3: Installation Experience (P1-High)](#5-work-stream-3-installation-experience)
6. [Work Stream 4: GPU & Driver Enablement (P1-High)](#6-work-stream-4-gpu--driver-enablement)
7. [Work Stream 5: APT Repository Infrastructure (P1-High)](#7-work-stream-5-apt-repository-infrastructure)
8. [Work Stream 6: Security & Supply Chain (P2-Medium)](#8-work-stream-6-security--supply-chain)
9. [Work Stream 7: Branding & Marketing Readiness (P1-High)](#9-work-stream-7-branding--marketing-readiness)
10. [Work Stream 8: Post-Launch Maturity (P3-Low)](#10-work-stream-8-post-launch-maturity)
11. [Dependencies & Integration Map](#11-dependencies--integration-map)
12. [Risk Register](#12-risk-register)
13. [Release Criteria & Go/No-Go Checklist](#13-release-criteria--gono-go-checklist)
14. [Appendix: Repository Inventory](#14-appendix-repository-inventory)

---

## 1. Product Vision & Overview

### 1.1 What Is CX Linux?

CX Linux is an **AI-native operating system** built on Debian/Ubuntu that translates natural language commands into Linux operations. It ships as a bootable ISO image containing:

- **`cx` CLI** - AI-powered package manager that understands plain English
- **Local LLM runtime** - Offline AI inference via Ollama/PyTorch
- **GPU acceleration** - NVIDIA CUDA and AMD ROCm support
- **Security-first design** - Firejail sandboxing, AppArmor, hardened defaults
- **Full GNOME desktop** - Branded desktop experience with 57 system customizations

### 1.2 Distribution Model

| Channel | Format | Audience |
|---------|--------|----------|
| **ISO Download** | Bootable hybrid ISO (UEFI + BIOS) | End users, evaluators |
| **APT Repository** | `apt install cx-core` on existing Debian/Ubuntu | Developers, sysadmins |
| **GitHub Releases** | Tagged ISO + .deb artifacts | CI/CD, automation |

### 1.3 Target Users

- **Primary:** Linux server administrators who want AI-assisted management
- **Secondary:** Developers wanting GPU-accelerated local AI inference
- **Tertiary:** Enterprise teams evaluating AI-native infrastructure

### 1.4 Competitive Positioning

CX Linux differentiates from standard Ubuntu/Debian by:
1. Natural language interface to system administration (`cx` CLI)
2. Pre-configured local LLM with GPU acceleration
3. Security-hardened defaults with compliance tooling (SecOps edition)
4. Curated meta-packages for common server workloads

---

## 2. Current State Assessment

### 2.1 What Exists Today

The repository contains a **substantial but unshipped** system. The build infrastructure, packages, and CI workflows are defined but have never produced a publicly available artifact.

#### Build System
- **Primary build:** `src/build.sh` (845 lines) - Full debootstrap + chroot build pipeline
- **Alternative build:** `Makefile` with live-build configuration (184 lines)
- **57 system mods** in `src/mods/` - Ordered shell scripts that customize the chroot (GNOME, branding, Ubiquity, Plymouth, localization, etc.)
- **Architecture support:** amd64 (primary), arm64 (secondary)
- **Base:** Ubuntu Plucky (25.04) via debootstrap, configurable via `src/args.sh`

#### Packages (8 defined, 0 published)
| Package | Type | Architecture | Key Dependencies |
|---------|------|-------------|-----------------|
| `cx-core` | Meta-package | all | python3 (>= 3.11), firejail, python3-rich, python3-cryptography |
| `cx-full` | Meta-package | all | cx-core, docker.io, nginx-light, certbot, prometheus-node-exporter, btop, fzf, ripgrep, bat |
| `cx-llm` | Meta-package | all | cx-core, python3-numpy, python3-scipy, libopenblas0 |
| `cx-gpu-nvidia` | Meta-package | amd64 | cx-core; Recommends: nvidia-driver, nvidia-cuda-toolkit, nvidia-container-toolkit |
| `cx-gpu-amd` | Meta-package | amd64 | cx-core, firmware-amd-graphics; Recommends: mesa-vulkan-drivers |
| `cx-secops` | Meta-package | all | cx-core, auditd, aide, fail2ban, rkhunter, clamav, lynis, tripwire, nftables |
| `cx-archive-keyring` | GPG keyring | all | (standalone) |
| `cortex-branding` | Branding | all | plymouth, plymouth-themes; Recommends: gnome-shell, gdm3 |

**Note:** `cx-model-tiny`, `cx-model-base`, `cx-gpu-nvidia-datacenter`, and `cx-gpu-amd-rocm` are also defined as sub-packages within the above control files.

#### CI/CD Workflows
| Workflow | File | Status |
|----------|------|--------|
| `Build ISO` | `.github/workflows/build-iso.yml` (210 lines) | Exists but ISO build has not been validated end-to-end; release job triggers on `v*` tags |
| `P0 Installation Tests` | `.github/workflows/installation-tests.yml` (341 lines) | Tests Ubuntu 24.04, Debian 12, upgrade path, package comparison, GPG signature verification; all tests expect packages at `repo.cxlinux-ai.com` which is not deployed |

#### APT Repository
- **Structure:** `apt/` directory with reprepro config, `conf/distributions` (stable: `cx`, testing: `cx-testing`)
- **GPG key:** `apt/deploy/pub.gpg` (signing key ID: `9FA39683613B13D0`)
- **Signing script:** `apt/scripts/sign-release.sh`
- **Packages directory:** `apt/packages/` - empty (`.gitkeep` only)
- **DNS/Hosting:** NOT deployed. `repo.cxlinux-ai.com` is not resolving.

#### Test Infrastructure
- `tests/installation-tests.sh` (comprehensive bash test suite)
- `tests/Vagrantfile` (Ubuntu 24.04, Debian 12, NVIDIA VMs)
- `tests/TEST_RESULTS.md` - Documents "NOT YET DEPLOYED" status as of Jan 25, 2026

### 2.2 What's Been Merged (Closed PRs)

| PR | Title | Impact |
|----|-------|--------|
| #10 | Bootstrap cortex linux distro hybrid ISO | Core build system, all 57 mods, UEFI/BIOS boot, Ubiquity installer |
| #21 | Update BSL license to 6-year conversion | Legal compliance |

### 2.3 What's Open (Pending PRs)

| PR | Title | Impact | Action Needed |
|----|-------|--------|---------------|
| #60 | Fix clone URL from cortex-distro to cx-distro | Naming consistency | Merge |
| #61 | Add SPDX license identifier for BSL 1.1 | Legal compliance | Merge |
| #62 | Unify all domain references to cxlinux.ai | Branding consistency | Merge |
| #51 | Add copilot-instructions.md | Agent onboarding (draft) | Review/Merge |

### 2.4 Open Epics & Issues

#### v1.0 MVP Milestone (March 30, 2026) - 0% Complete
| Issue | Title | Priority |
|-------|-------|----------|
| #3 | Debian base selection and compatibility contract | P0 |
| #4 | Debian packaging strategy for Cortex components | P0 |
| (unlisted) | #2 - Package repository and apt trust model | P0 |

#### v1.1 Phase 2 Milestone (June 29, 2026) - 0% Complete
| Issue | Title | Priority |
|-------|-------|----------|
| #5 | GPU driver enablement and packaging (NVIDIA/AMD) | P1 |
| #6 | ISO image build system (live-build vs debian-installer) | P1 |
| #7 | Kernel, firmware, and hardware enablement plan | P1 |
| #9 | Upgrade, rollback, and version pinning | P1 |
| #8 | Reproducible builds, artifact signing, and SBOM outputs | P2 |

#### Actionable Issues (No Milestone)
| Issue | Title | Assignee | Priority |
|-------|-------|----------|----------|
| #54 | Automated ISO build and publish workflow | Unassigned | P0 (implicit) |
| #55 | Build and publish cx-core .deb | Anshgrover23 | High |
| #56 | Build and publish cx-stacks .deb | Anshgrover23 | Medium |
| #57 | Build and publish cx-ops .deb | Anshgrover23 | Medium |
| #58 | Test apt install flow on Ubuntu 24.04 | Anshgrover23 | High |
| #59 | Record demo GIFs for README | Anshgrover23 | Medium |
| #46 | Integrate Calamares graphical installer | Anshgrover23 | Medium |

---

## 3. Work Stream 1: Package Pipeline

**Priority:** P0-CRITICAL | **Relates to:** Issues #4, #55, #56, #57, #58
**Goal:** A user can run `apt install cx-core` on Ubuntu 24.04 and get a working CX Linux installation.

### 3.1 Feature: Build and Publish cx-core .deb (Issue #55)

**Current State:** Package structure exists at `packages/cx-core/debian/` with control, changelog, and rules files. Package has never been built in CI or published.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| PKG-1 | GitHub Actions workflow builds cx-core .deb on release tags | Workflow triggered by `v*` tags; produces `cx-core_0.1.0-1_all.deb` artifact |
| PKG-2 | Package installs on clean Ubuntu 24.04 | `sudo apt install ./cx-core_*.deb` succeeds; `dpkg -l cx-core` shows `ii` status |
| PKG-3 | Binary installs to `/usr/bin/cx` | `which cx` returns `/usr/bin/cx`; `cx --version` responds |
| PKG-4 | Dependencies auto-resolve | `python3 (>= 3.11)`, `firejail` installed automatically |
| PKG-5 | GPG signature validates | `dpkg-sig --verify cx-core_*.deb` passes |
| PKG-6 | Package published to APT repository | `apt update && apt install cx-core` succeeds after adding repo |

**Technical Solution:**
- Existing `build-iso.yml` workflow already builds cx-core in a Debian Bookworm Docker container using `dpkg-buildpackage -us -uc -b`
- Missing: GPG signing step, upload to APT repo step, repo index regeneration
- Requires: GPG signing key in GitHub Secrets, deploy mechanism to `apt.cxlinux.ai`

**Implementation Steps:**
1. Add GPG signing to existing package build step in `build-iso.yml`
2. Add job step: upload .deb to APT repository (GitHub Pages or dedicated host)
3. Add job step: run `reprepro includedeb cx *.deb` and push updated repo index
4. Verify with `installation-tests.yml` workflow

### 3.2 Feature: Build and Publish cx-full .deb

**Current State:** Package structure exists at `packages/cx-full/debian/`. Depends on cx-core.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| PKG-7 | cx-full builds and installs | `apt install cx-full` pulls in cx-core + all server tools |
| PKG-8 | Docker and container tools available | `docker --version` and `containerd --version` respond |
| PKG-9 | Security tools configured | `fail2ban`, `nftables`, `auditd` running as services |
| PKG-10 | Monitoring agent running | `prometheus-node-exporter` service active |

### 3.3 Feature: Build and Publish cx-ops .deb (Issue #57)

**Current State:** No `packages/cx-ops/` directory exists. This package needs to be created from the cx main repository's ops module.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| PKG-11 | Create debian package structure for cx-ops | `packages/cx-ops/debian/{control,changelog,rules}` exists |
| PKG-12 | Package installs cleanly | `apt install cx-ops` succeeds with dependencies: cx-core, python3-psutil |
| PKG-13 | `cx doctor` command works | Running `cx doctor` performs health checks and produces output |

### 3.4 Feature: Build and Publish cx-stacks .deb (Issue #56)

**Current State:** No `packages/cx-stacks/` directory exists.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| PKG-14 | Create debian package structure for cx-stacks | `packages/cx-stacks/debian/{control,changelog,rules}` exists |
| PKG-15 | Package installs cleanly | `apt install cx-stacks` succeeds with dependencies: cx-core, python3-yaml, python3-docker |
| PKG-16 | `cx-stacks deploy lamp` works | LAMP stack deploys successfully after installation |

### 3.5 Feature: End-to-End APT Install Verification (Issue #58)

**Current State:** `tests/installation-tests.sh` and `.github/workflows/installation-tests.yml` exist but can't pass because packages aren't published.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| PKG-17 | Fresh install on Ubuntu 24.04 | `apt update && apt install cx-core` succeeds on clean system |
| PKG-18 | Fresh install on Debian 12 | Same flow works in Debian Bookworm container |
| PKG-19 | Upgrade path works | Install v0.1.0, upgrade to v0.2.0 via `apt upgrade` |
| PKG-20 | Clean uninstall | `apt purge cx-core` leaves no files in `/etc/cx/`, `/var/lib/cx/`, `/usr/local/bin/cx` |
| PKG-21 | Package comparison passes | cx-core < cx-full in disk usage; all declared dependencies install |

**Blocking Dependency:** Requires PKG-1 through PKG-6 complete first.

---

## 4. Work Stream 2: ISO Build & Release

**Priority:** P0-CRITICAL | **Relates to:** Issues #6, #54
**Goal:** A tag push to `v*` automatically builds an ISO, uploads it to GitHub Releases, and a user can download, boot, and install CX Linux.

### 4.1 Feature: Automated ISO Build Pipeline (Issue #54)

**Current State:**
- `src/build.sh` is a complete 845-line build script using debootstrap + chroot (not live-build)
- `Makefile` has an alternative live-build based pipeline
- `.github/workflows/build-iso.yml` exists with package build, ISO build, and release jobs
- The build workflow uses the Makefile/live-build path, NOT the debootstrap path in `src/build.sh`
- **Neither path has been validated end-to-end in CI.**

**Key Architectural Decision:** The repo has TWO build systems:
1. **`src/build.sh`** (debootstrap) - Full-featured, 57 mods, GNOME desktop, Ubiquity installer, used by PR #10
2. **`Makefile`** (live-build) - Simpler, uses `lb config`/`lb build`, defined in `iso/live-build/`

**Recommendation:** Use `src/build.sh` as the primary build system since it contains all 57 mods and is the actively developed path. The Makefile/live-build path appears to be a secondary approach that was added but not fully integrated.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| ISO-1 | Tag push triggers ISO build | Pushing `v0.1.0` tag triggers workflow |
| ISO-2 | ISO builds successfully in CI | Workflow completes without error; produces `.iso` file |
| ISO-3 | ISO uploaded to GitHub Releases | Release page shows ISO download link |
| ISO-4 | SHA256/SHA512 checksums published | `SHA256SUMS` and `SHA512SUMS` files in release |
| ISO-5 | SBOM included in release | CycloneDX and/or SPDX JSON in release |
| ISO-6 | Release notes auto-generated | Release body contains version, download instructions, verification commands |
| ISO-7 | Pre-release detection works | Tags containing `alpha`, `beta`, or `rc` marked as pre-release |
| ISO-8 | QEMU smoke test passes | ISO boots to GRUB menu in QEMU (automated check) |

**Technical Solution:**

```
Workflow: build-iso.yml (revised)
├── Job 1: build-packages
│   ├── Build cx-archive-keyring, cx-core, cx-full in Debian container
│   └── Upload as artifacts
├── Job 2: build-iso
│   ├── Free disk space (jlumbroso/free-disk-space)
│   ├── Run src/build.sh (or make iso) in privileged container
│   ├── Generate checksums
│   └── Upload ISO + checksums as artifacts
├── Job 3: verify
│   ├── Download ISO artifact
│   ├── Install qemu-system-x86_64
│   ├── Boot ISO in QEMU with timeout (verify GRUB menu appears)
│   └── Validate checksums
└── Job 4: release (on v* tags only)
    ├── Download all artifacts
    ├── Create GitHub Release with auto-generated notes
    └── Upload ISO, .debs, checksums, SBOM
```

**Implementation Steps:**
1. Decide on primary build path (recommend `src/build.sh`)
2. Update `build-iso.yml` to use chosen build path
3. Add QEMU smoke test job
4. Add SBOM generation step (`make sbom` or `syft`)
5. Test full pipeline with a `v0.1.0-alpha.1` tag
6. Fix any issues, then produce `v0.1.0` release

### 4.2 Feature: ISO Boot Verification

**Current State:** No automated boot testing exists.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| ISO-9 | ISO boots in UEFI mode | QEMU with OVMF firmware shows GRUB menu |
| ISO-10 | ISO boots in Legacy BIOS mode | QEMU without OVMF shows GRUB menu |
| ISO-11 | Live session starts | Selecting "Try and Install" reaches GNOME desktop |
| ISO-12 | Safe Graphics mode works | `nomodeset` kernel parameter applied, boots without GPU driver |

**Current GRUB menu entries** (from `src/build.sh` line 259-281):
- "Try and Install Cortex Linux" (live session)
- "Try and Install Cortex Linux (Safe Graphics)" (nomodeset)
- "Cortex Linux To Go (Persistent on USB)"
- "Cortex Linux To Go (Safe Graphics)"
- "Boot from next volume" (EFI only)
- "UEFI Firmware Settings" (EFI only)

### 4.3 Feature: ISO Variants

**Current State:** Only one ISO variant is built (full desktop). No minimal/server/secops variants.

**Requirements for v1.0:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| ISO-13 | Desktop edition (default) | Full GNOME desktop + cx-core + cx-full + branding |

**Requirements for v1.1:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| ISO-14 | Server edition | No GUI; includes cx-core + cx-full + SSH |
| ISO-15 | Core/Minimal edition | CLI only; cx-core + minimal packages |
| ISO-16 | SecOps edition | cx-core + cx-secops + hardened config |

---

## 5. Work Stream 3: Installation Experience

**Priority:** P1-HIGH | **Relates to:** Issues #46, closed issues #16, #17
**Goal:** A user who boots the ISO can complete installation without confusion.

### 5.1 Feature: Ubiquity Installer (Current)

**Current State:** Mods `21-ubiquity-mod` and `22-ubiquity-patch` customize the standard Ubuntu Ubiquity installer. This is the current installer embedded in the ISO via PR #10.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| INST-1 | Ubiquity installer launches | Clicking "Install" from live desktop opens installer |
| INST-2 | Disk partitioning works | UEFI: creates ESP + root; BIOS: creates MBR + root |
| INST-3 | User account created | Username, password, hostname configured |
| INST-4 | CX Linux branding shown | Installer uses CX Linux name, logo, color scheme |
| INST-5 | Installation completes | Reboot into installed system with GRUB |

### 5.2 Feature: Calamares Graphical Installer (Issue #46, Future)

**Current State:** Issue #46 proposes replacing Ubiquity with Calamares. Design spec includes dark theme (`#0F0F23` background, `#6B21A8` purple, `#06B6D4` cyan) and 4-6 slide installation slideshow. Medium priority - Ubiquity works for v1.0.

**Requirements (v1.1):**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| INST-6 | Calamares packaged as .deb | `packages/calamares-cx/` with CX-specific config |
| INST-7 | CX branding theme applied | Dark theme with purple/cyan accents |
| INST-8 | Installation slideshow | 4-6 slides introducing CX Linux features during install |
| INST-9 | UEFI + BIOS support | Works on both boot modes |
| INST-10 | d-i retained as advanced option | Debian Installer still available for server/automation |

### 5.3 Feature: First-Boot Experience

**Current State:** Closed Issue #17 suggests first-boot was addressed, but no dedicated first-boot wizard code is visible in the mods. Mods `35-dconf-patch`, `43-etc-branding-mod`, and `45-etc-issue-patch` customize the post-install environment but don't provide an interactive wizard.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| INST-11 | Welcome screen on first login | User sees CX Linux welcome with getting-started info |
| INST-12 | AI assistant introduction | Brief explanation of `cx` CLI with example commands |
| INST-13 | Example command suggestions | Context-aware examples based on system type |

### 5.4 Feature: Preseed/Automated Installation

**Current State:** `src/args.sh` includes preseed references. `TARGET_PACKAGE_REMOVE` suggests Ubiquity is removed post-install. No dedicated preseed files exist in the repo.

**Requirements (v1.1):**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| INST-14 | Preseed configuration template | `preseed/cx-default.preseed` with automated install config |
| INST-15 | Hands-free install mode | Boot with `preseed/file=/cdrom/preseed/cx.preseed` completes without interaction |
| INST-16 | PXE boot support | Netboot image and pxelinux.cfg provided |

---

## 6. Work Stream 4: GPU & Driver Enablement

**Priority:** P1-HIGH | **Relates to:** Issue #5
**Goal:** CX Linux detects GPUs and offers easy driver installation.

### 6.1 Feature: NVIDIA Driver Package (cx-gpu-nvidia)

**Current State:** `packages/cx-gpu-nvidia/debian/control` defines the meta-package with Recommends for `nvidia-driver`, `nvidia-cuda-toolkit`, `nvidia-container-toolkit`. Also defines `cx-gpu-nvidia-datacenter` for NVLink/fabric systems.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| GPU-1 | cx-gpu-nvidia installs NVIDIA drivers | `apt install cx-gpu-nvidia` pulls nvidia-driver, nvidia-smi works |
| GPU-2 | CUDA toolkit available | `nvcc --version` responds after installation |
| GPU-3 | Container GPU passthrough | `docker run --gpus all nvidia/cuda:12.0-base nvidia-smi` works |
| GPU-4 | GPU detection at boot | `lspci | grep -i nvidia` detected, driver loaded automatically |
| GPU-5 | Secure Boot MOK enrollment | `cx gpu mok-setup` generates and enrolls MOK key (referenced in control file) |

### 6.2 Feature: AMD Driver Package (cx-gpu-amd)

**Current State:** `packages/cx-gpu-amd/debian/control` defines meta-package with `firmware-amd-graphics` dependency and `cx-gpu-amd-rocm` sub-package for compute.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| GPU-6 | cx-gpu-amd installs AMD drivers | `apt install cx-gpu-amd` pulls firmware, mesa-vulkan-drivers |
| GPU-7 | Vulkan support works | `vulkaninfo` responds with AMD GPU info |
| GPU-8 | ROCm compute available | `apt install cx-gpu-amd-rocm` installs HIP runtime; `rocminfo` shows GPU |

### 6.3 Feature: GPU Detection Wizard

**Current State:** No wizard exists. The `cx-gpu-nvidia` control file references `cx gpu mok-setup` command but it's unclear if this is implemented in the `cx` CLI.

**Requirements (v1.1):**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| GPU-9 | Automatic GPU detection | System detects NVIDIA/AMD GPU via PCI IDs on first boot |
| GPU-10 | Driver recommendation | System suggests appropriate driver package based on GPU model |
| GPU-11 | Interactive installation | Guided flow: detect -> recommend -> confirm -> install -> verify |

---

## 7. Work Stream 5: APT Repository Infrastructure

**Priority:** P1-HIGH | **Relates to:** Issue #2 (unlisted), current `apt/` directory
**Goal:** Users can add the CX Linux APT repository and install packages with standard `apt` commands.

### 7.1 Feature: Repository Deployment

**Current State:**
- `apt/conf/distributions` defines `cx` (stable) and `cx-testing` channels for `amd64 arm64 source`
- GPG key exists: `apt/deploy/pub.gpg`
- Signing script exists: `apt/scripts/sign-release.sh`
- `apt/packages/` directory is **empty**
- `apt/deploy/CNAME` contains domain reference
- `repo.cxlinux-ai.com` DNS is **NOT resolving**
- Source list templates exist: `apt/cxlinux.list` and `apt/cxlinux.sources` (deb822 format)

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| APT-1 | Repository hosted and accessible | `curl -fsSL https://apt.cxlinux.ai/pub.gpg` returns GPG key |
| APT-2 | DNS resolves | `apt.cxlinux.ai` resolves to hosting infrastructure |
| APT-3 | Repository index generated | `apt update` with CX repo configured succeeds |
| APT-4 | Package download works | `apt install cx-core` downloads and installs from repo |
| APT-5 | GPG signature verification passes | `apt update` shows no signature warnings |
| APT-6 | Stable and testing channels available | Both `cx` and `cx-testing` codenames have Release files |

**Technical Solution Options:**

| Option | Pros | Cons |
|--------|------|------|
| **GitHub Pages** (apt-repo) | Free, simple, existing deploy/ structure | Size limits, no CDN control |
| **Cloudflare R2 + Workers** | CDN, no egress costs, custom domain | More setup, ongoing cost |
| **GitHub Releases as source** | Already planned for ISO | Not a proper APT repo |

**Recommendation:** Start with GitHub Pages for v1.0 (it's already partially set up in `apt/deploy/`), migrate to Cloudflare R2 for v1.1 when scale matters.

### 7.2 Feature: Repository Update Automation

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| APT-7 | CI publishes packages on release | Tag push builds .debs and pushes to APT repo |
| APT-8 | Repository index auto-regenerated | `reprepro includedeb` + `sign-release.sh` runs in CI |
| APT-9 | Testing channel receives pre-releases | Alpha/beta tags publish to `cx-testing`, stable tags to `cx` |

### 7.3 Feature: One-Line Install Script

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| APT-10 | Curl-pipe install works | `curl -fsSL https://cxlinux.ai/install \| sudo bash` adds repo + installs cx-core |
| APT-11 | Script verifies GPG key fingerprint | Key fingerprint checked before importing |
| APT-12 | Script supports Ubuntu 24.04 + Debian 12 | OS detection, appropriate sources.list format |

---

## 8. Work Stream 6: Security & Supply Chain

**Priority:** P2-MEDIUM | **Relates to:** Issue #8
**Goal:** Enterprise buyers can verify the provenance and security of CX Linux packages and ISOs.

### 8.1 Feature: SBOM Generation

**Current State:** `Makefile` has `make sbom` target using `syft` and `cyclonedx-cli`. Never been run in CI.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| SEC-1 | SBOM generated for each ISO | CycloneDX JSON and SPDX JSON included in release |
| SEC-2 | SBOM generated for each .deb | Package-level SBOM available |
| SEC-3 | SBOM includes all transitive dependencies | Complete dependency tree captured |

### 8.2 Feature: Vulnerability Scanning

**Requirements (v1.1):**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| SEC-4 | CVE scan on SBOM | `grype` or equivalent scans SBOM; no critical CVEs in release |
| SEC-5 | Scan blocks release | CI fails if critical CVEs found |

### 8.3 Feature: License Compliance

**Requirements (v1.1):**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| SEC-6 | License audit on all packages | All included packages have GPL/MIT/Apache/BSD compatible licenses |
| SEC-7 | Non-free firmware documented | firmware-misc-nonfree, firmware-linux-nonfree listed in SBOM with license notes |

### 8.4 Feature: Artifact Signing

**Current State:** GPG key exists. `sign-release.sh` signs repository metadata. ISO gets SHA256 checksum but is not GPG-signed.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| SEC-8 | ISO GPG-signed | `*.iso.asc` detached signature published alongside ISO |
| SEC-9 | .deb packages GPG-signed | `dpkg-sig --verify *.deb` passes |
| SEC-10 | Release metadata signed | `Release.gpg` valid in APT repository |

---

## 9. Work Stream 7: Branding & Marketing Readiness

**Priority:** P1-HIGH | **Relates to:** Issues #59, PRs #60, #61, #62
**Goal:** CX Linux presents a professional, consistent brand identity across all touchpoints.

### 9.1 Feature: Brand Consistency (PRs #60, #61, #62)

**Current State:** The repo has remnants of the old "Cortex Linux" / "cortexlinux" naming:
- `cortex-branding` package still references `cortexlinux.com` in control file
- `src/args.sh` line 85-89: `TARGET_NAME="cortex"`, `TARGET_BUSINESS_NAME="Cortex Linux"`
- README line 22: clone URL points to `cortex-distro`
- Various old domain references throughout

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| BRAND-1 | All code references use "cx" / "CX Linux" | No "cortex" references in user-facing strings |
| BRAND-2 | All URLs point to cxlinux.ai domain | No cortexlinux.com references |
| BRAND-3 | Package names use cx- prefix | Already done for most; `cortex-branding` needs rename to `cx-branding` |
| BRAND-4 | SPDX license identifier present | BSL 1.1 properly identified |

**Implementation:** Merge PRs #60, #61, #62. Then audit remaining `cortex` references in `src/args.sh`, `cortex-branding/debian/control`, and mods.

### 9.2 Feature: Visual Identity

**Current State:**
- GRUB theme exists in `packages/cortex-branding/boot/grub/themes/cortex/`
- Plymouth patch: `src/mods/19-plymouth-patch`
- Desktop mods: 57 mods covering GNOME extensions, wallpaper, icons, dash-to-panel, arc menu
- OS identity: `src/mods/43-etc-branding-mod` (sets `/etc/os-release`, MOTD, etc.)
- Neofetch: `src/mods/36-ubuntu-logo-text` (custom ASCII art)

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| BRAND-5 | GRUB boot menu shows CX Linux branding | Logo, color scheme, menu entries properly themed |
| BRAND-6 | Plymouth splash displays during boot | CX Linux logo shown during boot sequence |
| BRAND-7 | GDM login screen branded | CX Linux styling on login screen |
| BRAND-8 | GNOME desktop fully branded | Wallpaper, icons, dash-to-panel, arc menu configured |
| BRAND-9 | `neofetch` / `fastfetch` shows CX Linux | Custom ASCII art and OS name displayed |
| BRAND-10 | `/etc/os-release` identifies CX Linux | `NAME="CX Linux"`, proper version, URLs |

### 9.3 Feature: Demo Content (Issue #59)

**Current State:** Issue requests three demo GIFs for the README showing `cx` CLI in action.

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| BRAND-11 | CUDA installation demo GIF | Shows `cx install cuda drivers for my nvidia gpu` with GPU detection |
| BRAND-12 | LAMP stack demo GIF | Shows `cx setup lamp stack with php 8.3` with plan + execution |
| BRAND-13 | Disk space analysis demo GIF | Shows `cx what packages use the most disk space` with table output |
| BRAND-14 | GIFs embedded in README | All three GIFs visible in repository README |
| BRAND-15 | Each GIF under 5 seconds | Concise, clear terminal recordings |

### 9.4 Feature: Marketing Website Alignment

**Requirements:**

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| BRAND-16 | Download page links to GitHub Releases | cxlinux.ai/download points to latest ISO |
| BRAND-17 | Installation docs accurate | Getting started guide matches actual install experience |
| BRAND-18 | APT repo setup docs accurate | Copy-paste commands work on Ubuntu 24.04 + Debian 12 |

---

## 10. Work Stream 8: Post-Launch Maturity

**Priority:** P3-LOW | **Relates to:** Issues #7, #9
**Target:** v1.1+ (post-launch iterations)

### 10.1 Features Deferred to v1.1+

| ID | Feature | Rationale for Deferral |
|----|---------|----------------------|
| POST-1 | APT repository CDN (Cloudflare R2) | GitHub Pages sufficient for launch |
| POST-2 | Repository mirroring | Not needed until significant user base |
| POST-3 | Repository download metrics | Nice-to-have for analytics |
| POST-4 | PXE/network installation | Enterprise feature |
| POST-5 | ARM64 ISO variant | amd64 is primary target |
| POST-6 | Reproducible builds verification | Important but not launch-blocking |
| POST-7 | Upgrade/rollback/version pinning (Issue #9) | Requires stable package baseline first |
| POST-8 | Kernel/firmware hardware enablement (Issue #7) | Standard Debian kernel sufficient for launch |
| POST-9 | Build caching in CI | Optimization, not functionality |
| POST-10 | WiFi/Ethernet/peripheral driver databases | Standard Debian drivers sufficient for launch |
| POST-11 | Touch screen support | Niche use case |
| POST-12 | RGB controller support | Niche use case |
| POST-13 | Printer/scanner support | Standard CUPS sufficient |
| POST-14 | Server ISO variant | Desktop ISO covers most use cases |
| POST-15 | SecOps dedicated ISO | Package installable via APT |

---

## 11. Dependencies & Integration Map

```
                    ┌──────────────┐
                    │  cx (CLI)    │ ◄── External repo: cxlinux-ai/cortex
                    │  /usr/bin/cx │     Must be built + available as .deb
                    └──────┬───────┘
                           │ depends
              ┌────────────┼────────────┐
              ▼            ▼            ▼
     ┌──────────────┐ ┌─────────┐ ┌──────────┐
     │   cx-core    │ │ cx-ops  │ │cx-stacks │
     │ meta-package │ │ doctor  │ │ LAMP etc │
     └──────┬───────┘ └────┬────┘ └────┬─────┘
            │              │           │
            │ depends      │           │
     ┌──────┴───────┐     │           │
     │   cx-full    │     │           │
     │ server tools │     │           │
     └──────┬───────┘     │           │
            │              │           │
            ├──────────────┼───────────┘
            ▼
     ┌──────────────────────────┐
     │     APT Repository       │
     │  apt.cxlinux.ai          │
     │  ├── cx (stable)         │
     │  └── cx-testing          │
     └──────────┬───────────────┘
                │ downloaded by
                ▼
     ┌──────────────────────────┐
     │        ISO Build         │
     │  src/build.sh            │
     │  ├── debootstrap         │ ◄── Uses Ubuntu Plucky (25.04) base
     │  ├── 57 mods (chroot)    │
     │  ├── Ubiquity installer  │
     │  └── xorriso ISO output  │
     └──────────┬───────────────┘
                │ produces
                ▼
     ┌──────────────────────────┐
     │     GitHub Releases      │
     │  ├── cx-linux-*.iso      │
     │  ├── SHA256SUMS          │
     │  ├── *.deb packages      │
     │  └── SBOM (CycloneDX)    │
     └──────────────────────────┘
```

### Critical External Dependencies

| Dependency | What It Provides | Risk |
|------------|-----------------|------|
| `cxlinux-ai/cortex` repo | The actual `cx` CLI binary/Python package | **HIGH** - Without this, cx-core installs an empty shell |
| Ubuntu Plucky (25.04) mirrors | Base system packages | LOW - Well-established mirrors |
| NVIDIA apt repo | Proprietary drivers, CUDA toolkit | MEDIUM - External dependency |
| Ollama | LLM inference runtime | MEDIUM - Recommended, not required |
| GitHub Pages/hosting | APT repo hosting | LOW - Multiple alternatives |

---

## 12. Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| R1 | **cx CLI binary doesn't exist or isn't packaged** - cx-core control file declares `/usr/bin/cx` but the actual Python application may not be in this repo | HIGH | CRITICAL | Verify cxlinux-ai/cortex repo has a working, packageable CLI; coordinate packaging |
| R2 | **Anshgrover23 is single point of failure** - 6 of 7 actionable issues assigned to one person | HIGH | HIGH | Distribute work across team; unblock parallel tracks |
| R3 | **v1.0 MVP milestone at 0% with 7 weeks remaining** | HIGH | HIGH | Focus exclusively on Work Streams 1-2; defer everything else |
| R4 | **57 mods never validated as cohesive system** - Individual mods may work but produce broken desktop together | MEDIUM | HIGH | Full integration test on real/virtual hardware before release |
| R5 | **Two competing build systems** - `src/build.sh` (debootstrap) vs `Makefile` (live-build) confusion | MEDIUM | MEDIUM | Pick one as canonical, document decision, potentially deprecate the other |
| R6 | **Naming inconsistency** - "Cortex" vs "CX" throughout codebase | HIGH | MEDIUM | Merge PRs #60, #61, #62 immediately; audit remaining references |
| R7 | **APT repo not deployed** - DNS not resolving, no packages published | CERTAIN | CRITICAL | This is the #1 blocker; deploy repo before anything else |
| R8 | **Ubuntu 25.04 (Plucky) is not LTS** - Base system has short support window | MEDIUM | MEDIUM | Consider switching to 24.04 LTS (Noble) for production stability |
| R9 | **Closed issues may not reflect shipped features** - Issues #11-#20 closed Jan 15 may be planning closures | MEDIUM | MEDIUM | Re-verify each closed feature in actual build output |
| R10 | **BSL 1.1 license may deter some users** | LOW | MEDIUM | Clear documentation of license terms; 6-year Apache 2.0 conversion |

---

## 13. Release Criteria & Go/No-Go Checklist

### v1.0 MVP (Target: March 30, 2026)

#### Must-Have (All must PASS)

| # | Criterion | Test Method | Status |
|---|-----------|-------------|--------|
| GO-1 | `apt install cx-core` works on clean Ubuntu 24.04 | `installation-tests.yml` Ubuntu job | NOT TESTED |
| GO-2 | `apt install cx-full` works on clean Ubuntu 24.04 | `installation-tests.yml` comparison job | NOT TESTED |
| GO-3 | ISO downloads from GitHub Releases | Manual: check release page | NOT AVAILABLE |
| GO-4 | ISO boots in UEFI mode (QEMU + OVMF) | Automated QEMU boot test | NOT TESTED |
| GO-5 | ISO boots in Legacy BIOS mode (QEMU) | Automated QEMU boot test | NOT TESTED |
| GO-6 | Ubiquity installer completes without errors | Manual test in VM | NOT TESTED |
| GO-7 | Installed system boots to GNOME desktop | Manual test in VM | NOT TESTED |
| GO-8 | `cx` CLI runs and responds | `cx --version` in installed system | NOT TESTED |
| GO-9 | CX Linux branding appears (GRUB + desktop) | Visual verification in VM | NOT TESTED |
| GO-10 | SHA256 checksums published alongside ISO | Check release artifacts | NOT AVAILABLE |
| GO-11 | GPG signatures verify correctly | `gpg --verify` on Release file | NOT TESTED |
| GO-12 | No "cortex" in user-facing strings | Grep audit | FAILING (known) |
| GO-13 | README accurately describes download + install | Manual review | NEEDS UPDATE |
| GO-14 | Clean uninstall leaves no files | `installation-tests.yml` uninstall job | NOT TESTED |

#### Should-Have (Target for v1.0, can slip to v1.0.1)

| # | Criterion | Status |
|---|-----------|--------|
| SH-1 | At least one demo GIF in README (Issue #59) | NOT DONE |
| SH-2 | cx-llm package installs Ollama runtime | NOT TESTED |
| SH-3 | NVIDIA driver package installs on GPU hardware | NOT TESTED |
| SH-4 | SBOM included in release | NOT DONE |
| SH-5 | First-boot welcome screen | UNCLEAR |

### v1.1 Phase 2 (Target: June 29, 2026)

| # | Criterion |
|---|-----------|
| V11-1 | Calamares installer available |
| V11-2 | Server ISO variant |
| V11-3 | NVIDIA + AMD GPU tested on real hardware |
| V11-4 | Reproducible builds verified |
| V11-5 | Upgrade path (v1.0 -> v1.1) tested |
| V11-6 | APT repo on CDN |
| V11-7 | Vulnerability scanning in CI |
| V11-8 | Preseed/automated installation |

---

## 14. Appendix: Repository Inventory

### A. Build System Mods (57 total in `src/mods/`)

| Mod | Purpose | Category |
|-----|---------|----------|
| 00-check-host-mod | Verify host environment | System |
| 01-apt-source-mod | Configure APT sources | System |
| 02-set-hostname-mod | Set hostname | System |
| 03-systemd-mod | Configure systemd | System |
| 04-machine-id-mod | Reset machine ID | System |
| 05-initctl-mod | Configure initctl | System |
| 06-apt-upgrade-mod | Upgrade base packages | System |
| 07-system-tools-install-mod | Install core tools | System |
| 08-casper-and-kernel-install-mod | Install kernel + casper | Boot |
| 10-no-snap-mod | Remove snap | Customization |
| 12-no-motd-mod | Disable default MOTD | Customization |
| 14-gnome-apps-mod | Install GNOME applications | Desktop |
| 15-fonts-mod | Install fonts | Desktop |
| 16-localization-patch | Locale configuration | Localization |
| 17-appstore-app | App store setup | Desktop |
| 18-firefox-mod | Firefox browser install | Desktop |
| 19-plymouth-patch | Plymouth boot splash | Branding |
| 20-deskmon-mod | Desktop monitor | Desktop |
| 21-ubiquity-mod | Ubiquity installer | Installer |
| 22-ubiquity-patch | Ubiquity customization | Installer |
| 23-software-properties-common-patch | Software properties | Desktop |
| 23-software-properties-gtk | GTK software properties | Desktop |
| 23-wallpaper-mod | Desktop wallpaper | Branding |
| 26-gnome-extensions-installer | Install GNOME extensions | Desktop |
| 27-dash-to-panel-patch-mod | Dash-to-panel config | Desktop |
| 27-gnome-extensions-remover | Remove unwanted extensions | Desktop |
| 28-gnome-extensions-system-archiver | Archive system extensions | Desktop |
| 29-gnome-extension-cortex-loc | CX location extension | Desktop |
| 29-gnome-extension-cortex-switcher | CX switcher extension | Desktop |
| 29-gnome-extension-noti-bottom-right | Notification positioning | Desktop |
| 30-gnome-extension-arcmenu-patch | Arc menu config | Desktop |
| 31-gnome-extension-dashtopanel-patch | Dash-to-panel config | Desktop |
| 32-gnome-shell-localization-patch | Shell localization | Localization |
| 33-gnome-extensions-enabler | Enable extensions | Desktop |
| 35-dconf-patch | GNOME dconf settings | Desktop |
| 36-ubuntu-logo-text | Neofetch/fastfetch branding | Branding |
| 37-xdg-mime-mod | MIME type defaults | Desktop |
| 38-root-conf-cleanup | Clean root config | Cleanup |
| 39-templates-mod | File templates | Desktop |
| 40-do-cortex-upgrade-mod | CX upgrade helper | System |
| 41-target-apt-mirror-mod | APT mirror config | System |
| 42-gnome-sessions-patch | GNOME session config | Desktop |
| 42-intel-thesof-mod | Intel Sound Open Firmware | Hardware |
| 43-etc-branding-mod | /etc branding (os-release, etc) | Branding |
| 44-casper-patch | Casper live system patch | Boot |
| 45-etc-issue-patch | /etc/issue branding | Branding |
| 78-no-advertisements-mod | Remove ads | Customization |
| 79-useless-package-remover | Remove unneeded packages | Cleanup |
| 80-initramfs-update | Rebuild initramfs | Boot |
| 82-locales-config | Locale configuration | Localization |
| 83-network-manager-patch | NetworkManager config | System |
| 84-apt-cache-cleaner | Clean APT cache | Cleanup |
| 85-machine-id-wiper | Wipe machine ID for ISO | Cleanup |
| 86-diversion-remover | Remove dpkg diversions | Cleanup |
| 87-history-cleaner | Clean shell history | Cleanup |
| 88-useless-folders-cleaner | Remove empty folders | Cleanup |

### B. Package Inventory

| Package | Version | Size | Binaries |
|---------|---------|------|----------|
| cx-core | 0.1.0-1 | ~1KB (meta) | /usr/bin/cx (declared) |
| cx-full | 0.1.0-1 | ~1KB (meta) | (dependencies only) |
| cx-llm | 0.1.0-1 | ~1KB (meta) | (dependencies only) |
| cx-gpu-nvidia | 0.1.0-1 | ~1KB (meta) | (dependencies only) |
| cx-gpu-amd | 0.1.0-1 | ~1KB (meta) | (dependencies only) |
| cx-secops | 0.1.0-1 | ~1KB (meta) | (dependencies only) |
| cx-archive-keyring | 2025.01-1 | ~4KB | /usr/share/keyrings/cx-archive-keyring.gpg |
| cortex-branding | 0.1.0-1 | ~50KB+ | Plymouth theme, GRUB theme, wallpapers, os-release |
| cx-model-tiny | (planned) | ~500MB | LLM model files |
| cx-model-base | (planned) | ~2GB | LLM model files |

### C. CI/CD Workflow Inventory

| Workflow | Trigger | Jobs | Status |
|----------|---------|------|--------|
| `build-iso.yml` | push to main, tags `v*`, PR to main, manual | build-packages, build-iso, release | EXISTS - NOT VALIDATED |
| `installation-tests.yml` | push to main/develop, PR to main, manual | ubuntu-install, debian-install, upgrade-test, package-comparison, signature-test | EXISTS - PACKAGES NOT PUBLISHED |

---

*This PRD is a living document. Update status columns as work progresses. All requirement IDs (PKG-*, ISO-*, INST-*, GPU-*, APT-*, SEC-*, BRAND-*, POST-*) can be referenced in issue descriptions and PR titles for traceability.*
