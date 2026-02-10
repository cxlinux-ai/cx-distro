# CX-DISTRO Strategy Plan: Marketing Readiness Assessment

_Generated: 2026-02-10 | Based on: Repository audit, GitHub issues, closed PRs, milestone analysis_

---

## Executive Summary

CX-Distro has significant foundational infrastructure in place (build system, 57 system mods, 7 meta-packages, APT repo structure, CI workflows, branding). However, **none of the packages are published to the APT repository yet**, the **ISO has not been built and released through CI**, and several user-facing experiences (installer, first-boot, driver wizards) exist only as closed feature issues without verified, shippable implementations. The v1.0 MVP milestone (due March 30, 2026) has 0% completion with 3 P0-critical epics still open.

**Bottom line:** The distro is not marketable today. To reach a marketable state, the immediate priority is a working end-to-end pipeline: build packages, publish them, build a bootable ISO, and verify that a user can install and use CX Linux without manual intervention.

---

## Section 1: What's Already Done

### Build Pipeline (2.1.1)
| Item | Status | Evidence |
|------|--------|----------|
| Set up live-build infrastructure | **DONE** | Makefile with `lb config`, 30+ build params, Debian Trixie base |
| Create reproducible build scripts | **PARTIAL** | `src/build.sh` + 57 mods exist; no version pinning or timestamp reproducibility |
| GitHub Actions CI/CD for ISO builds | **PARTIAL** | `.github/workflows/build-iso.yml` exists (210 lines), but Issue #54 says automated release publishing doesn't work yet |
| Build artifact storage | **PARTIAL** | GitHub Actions artifacts (7-14 day retention); no CDN or permanent storage |
| Build versioning system | **PARTIAL** | VERSION=0.1.0 in Makefile, pre-release detection in workflow; no formal channels |
| Build caching | **NOT DONE** | No caching evident in CI workflows |

### Base System Configuration (2.1.2)
| Item | Status | Evidence |
|------|--------|----------|
| Select and configure Debian/Ubuntu base | **DONE** | Debian Trixie, config/release-amd64.json and arm64.json |
| Define minimal package set | **DONE** | cx-core control file with curated dependencies |
| Create cortex-core meta-package | **DONE** | `packages/cx-core/` with full debian/ structure |
| Create cortex-full meta-package | **DONE** | `packages/cx-full/` with Docker, monitoring, server tools |
| Create cortex-server meta-package | **NOT DONE** | No separate server package; cx-full covers some server use cases |
| Package dependency resolution | **PARTIAL** | Dependencies declared but packages not yet published (Issues #55-57) |

### Boot Configuration (2.1.3)
| Item | Status | Evidence |
|------|--------|----------|
| UEFI boot support | **DONE** | `grub-efi-amd64-bin` in Makefile, `--bootloaders "grub-efi,syslinux"` |
| Legacy BIOS boot support | **DONE** | `grub-pc-bin`, syslinux in build deps, `--binary-images iso-hybrid` |
| Boot menu with CX Linux branding | **DONE** | Full GRUB theme in `packages/cortex-branding/boot/grub/themes/cortex/` |
| Recovery mode option | **NOT DONE** | |
| Safe mode option | **NOT DONE** | |
| Boot splash screen | **PARTIAL** | Plymouth patch (mod 19-plymouth-patch) exists |

### ISO Variants (2.1.4)
| Item | Status | Evidence |
|------|--------|----------|
| CX Linux Core edition (minimal) | **PARTIAL** | Build target exists (`make iso`); not published |
| CX Linux Server edition | **NOT DONE** | No server-specific ISO profile |
| CX Linux Desktop edition | **PARTIAL** | 57 GNOME mods + cortex-branding; not published as ISO |
| CX Linux SecOps edition | **PARTIAL** | cx-secops package exists; no dedicated ISO |

### APT Repository (2.2.1)
| Item | Status | Evidence |
|------|--------|----------|
| GPG key generation and management | **DONE** | `apt/deploy/pub.gpg`, signing key ID 9FA39683613B13D0 |
| Repository structure | **DONE** | reprepro config, pool/dists hierarchy, stable/testing channels |
| Package signing workflow | **DONE** | `apt/scripts/sign-release.sh`, CI workflow |
| Repository mirroring | **NOT DONE** | |
| CDN distribution | **NOT DONE** | |
| Repository metrics | **NOT DONE** | |

### Package Management (2.2.2)
| Item | Status | Evidence |
|------|--------|----------|
| .deb packaging for cx-core | **DONE** (structure) | `packages/cx-core/debian/` - not yet published (Issue #55) |
| .deb packaging for cx-cli | **INCLUDED** | Part of cx-core package |
| .deb packaging for cx-terminal | **NOT DONE** | |
| .deb packaging for cx-llm | **DONE** (structure) | `packages/cx-llm/debian/` exists |
| Package update channels | **PARTIAL** | stable/testing defined in reprepro config |

### SBOM Generation (2.2.3)
| Item | Status | Evidence |
|------|--------|----------|
| SBOM generation | **PARTIAL** | `make sbom` target exists, syft/cyclonedx-cli in build deps |
| Vulnerability scanning | **NOT DONE** | |
| Compliance reporting | **NOT DONE** | |
| License compliance checking | **NOT DONE** | |

### Installation Experience (2.3)
| Item | Status | Evidence |
|------|--------|----------|
| Preseed configuration | **PARTIAL** | README mentions preseed; installer modes in build |
| Hands-free installation | **PARTIAL** | Closed Issue #16, but implementation unverified |
| Network installation | **PARTIAL** | `make iso-netinst` target exists |
| PXE boot configuration | **NOT DONE** | |
| Welcome wizard | **PARTIAL** | Closed Issue #17 |
| Calamares graphical installer | **NOT DONE** | Open Issue #46, assigned to Anshgrover23 |
| All other first-boot/post-install items | **NOT DONE** | |

### Driver Support (2.4)
| Item | Status | Evidence |
|------|--------|----------|
| NVIDIA driver detection + package | **PARTIAL** | `packages/cx-gpu-nvidia/` exists; no wizard |
| AMD driver detection + package | **PARTIAL** | `packages/cx-gpu-amd/` exists; no wizard |
| CUDA setup | **PARTIAL** | Included in cx-gpu-nvidia deps |
| Secure Boot MOK enrollment | **NOT DONE** | |
| ROCm setup | **NOT DONE** | |
| Network drivers (WiFi, Ethernet) | **NOT DONE** | |
| Peripheral drivers | **NOT DONE** | |

---

## Section 2: Open Issues & PRs Summary

### Active Milestones
- **v1.0 MVP** (due March 30, 2026) - 0/3 issues closed, 0% complete
  - #2 Package repository and apt trust model (P0)
  - #3 Debian base selection (P0)
  - #4 Debian packaging strategy (P0)
- **v1.1 Phase 2** (due June 29, 2026) - 0/6 issues closed, 0% complete
  - #1 Automated installation (P1)
  - #5 GPU drivers (P1)
  - #6 ISO build system (P1)
  - #7 Kernel/firmware/hardware (P1)
  - #8 Reproducible builds/SBOM (P2)
  - #9 Upgrade/rollback/pinning (P1)

### Actionable Open Issues
| Issue | Title | Priority | Assignee |
|-------|-------|----------|----------|
| #54 | Automated ISO build & publish workflow | P0 (implicit) | Unassigned |
| #55 | Build and publish cx-core .deb | High | Anshgrover23 |
| #56 | Build and publish cx-stacks .deb | Medium | Anshgrover23 |
| #57 | Build and publish cx-ops .deb | Medium | Anshgrover23 |
| #58 | Test apt install flow on Ubuntu 24.04 | High | Anshgrover23 |
| #59 | Record demo GIFs for README | Medium | Anshgrover23 |
| #46 | Integrate Calamares graphical installer | Medium | Anshgrover23 |

### Open PRs (Need Review/Merge)
| PR | Title | Impact |
|----|-------|--------|
| #60 | Fix clone URL from cortex-distro to cx-distro | Naming consistency |
| #61 | Add SPDX license identifier for BSL 1.1 | Legal compliance |
| #62 | Unify all domain references to cxlinux.ai | Branding consistency |

---

## Section 3: Priority Strategy for Marketing Readiness

### TIER 1 - CRITICAL PATH (Must complete before any marketing)

These items form the minimum viable distribution. Without them, there is nothing to market.

#### 1A. End-to-End Package Pipeline (Weeks 1-2)
_Blocks everything else. A distro that can't install packages is not a distro._

1. **Merge open branding PRs (#60, #61, #62)** - Domain and naming must be consistent before any public release
2. **Build and publish cx-core .deb to apt repo (Issue #55)** - The foundational package
3. **Build and publish cx-full .deb** - The full experience package
4. **Verify apt install flow end-to-end (Issue #58)** - `curl | apt install cx-core` must work on clean Ubuntu 24.04
5. **Build and publish cx-ops .deb (Issue #57)** - `cx doctor` is essential for support/troubleshooting

#### 1B. Automated ISO Build & Release (Weeks 2-3)
_Without a downloadable ISO, there's nothing to distribute._

6. **Fix CI/CD to produce and publish ISO (Issue #54)** - Tag-triggered builds that upload to GitHub Releases
7. **Produce one verified Desktop ISO (amd64)** - The first "golden image" you can hand to testers
8. **Generate SHA256/SHA512 checksums** - Already in workflow, needs to run end-to-end
9. **Smoke-test ISO boot in QEMU** - Verify the ISO actually boots (part of Issue #54 acceptance criteria)

#### 1C. Installation Must Work (Weeks 3-4)
_A user who downloads the ISO must be able to install CX Linux._

10. **Verify Ubiquity installer works with CX branding** - Mod 21/22 patches exist but need validation
11. **Verify first-boot flow completes** - Welcome wizard, account setup, basic config
12. **Test UEFI + Legacy BIOS boot** - Both paths must work

### TIER 2 - MARKETING DIFFERENTIATORS (Required to tell a compelling story)

These items distinguish CX Linux from "yet another Ubuntu respin." Marketing needs at least one strong narrative.

#### 2A. AI-Native Story (Weeks 4-6)
_This is likely the primary marketing angle._

13. **Verify cx-llm package installs Ollama and model runtime** - The "embedded AI" promise
14. **Create a working `cx` CLI demo** - Show `cx` running AI commands out of the box
15. **Record demo GIFs for README (Issue #59)** - Visual proof of the product
16. **Write "Getting Started with AI on CX Linux" docs** - First-party walkthrough

#### 2B. GPU Support Story (Weeks 4-6)
_Critical for AI workloads and a differentiator vs generic Linux._

17. **Verify cx-gpu-nvidia package installs correctly** - NVIDIA drivers + CUDA working
18. **Test GPU detection on real hardware or cloud GPU instance** - Prove it works
19. **Verify cx-gpu-amd package** - AMD path for ROCm users

#### 2C. Professional Branding (Weeks 3-5)
_The distro must look intentional and polished._

20. **Verify GRUB theme renders correctly** - Boot screen is first impression
21. **Verify Plymouth boot splash** - Smooth branded boot experience
22. **Verify desktop branding (wallpaper, icons, GNOME config)** - 57 mods must produce a cohesive desktop
23. **Verify neofetch/system info shows CX Linux branding** - Screen share / screenshot appeal

### TIER 3 - PRODUCTION READINESS (Required before recommending for production use)

#### 3A. Security & Supply Chain (Weeks 6-8)
24. **SBOM generation working (`make sbom`)** - Required for enterprise buyers
25. **GPG signature verification end-to-end** - Issue #58 tests cover this
26. **Vulnerability scanning on published packages** - Basic CVE check
27. **License compliance audit** - Verify all packages have compatible licenses

#### 3B. Additional Packages & Stacks (Weeks 6-8)
28. **Build and publish cx-stacks .deb (Issue #56)** - LAMP/Node/Django stacks
29. **Build and publish cx-secops .deb** - Security tools for enterprise appeal
30. **Create cortex-server meta-package** - Distinct server profile

#### 3C. Installer Polish (Weeks 8-10)
31. **Evaluate Calamares integration (Issue #46)** - Modern graphical installer
32. **Add recovery mode to boot menu** - Essential for support
33. **Add safe mode to boot menu** - Driver troubleshooting
34. **Preseed templates for automated deployment** - Enterprise/fleet use case

### TIER 4 - SCALE & MATURITY (Post-launch improvements)

35. APT repository CDN distribution
36. Repository mirroring
37. Repository metrics/analytics
38. Network/PXE installation support
39. WiFi chipset detection and driver database
40. Peripheral driver support (touch, RGB, printers, scanners)
41. Upgrade/rollback/version pinning system (Epic #9)
42. Reproducible builds verification (Epic #8)
43. Build caching for faster CI iterations
44. ARM64 ISO variant
45. SecOps dedicated ISO edition

---

## Section 4: Recommended Execution Order

```
PHASE 1: "Make It Work" (Target: v1.0 MVP by March 30)
├── Sprint 1: Package Pipeline
│   ├── Merge PRs #60, #61, #62
│   ├── Build + publish cx-core to apt repo
│   ├── Build + publish cx-full to apt repo
│   └── Verify apt install on Ubuntu 24.04
├── Sprint 2: ISO Pipeline
│   ├── Fix Issue #54 - automated ISO build
│   ├── Produce first golden Desktop ISO
│   └── QEMU smoke test
└── Sprint 3: Install Verification
    ├── Verify installer (Ubiquity) works
    ├── Verify UEFI + BIOS boot
    └── Verify first-boot wizard

PHASE 2: "Make It Marketable" (Target: 4-6 weeks post-MVP)
├── Sprint 4: AI Story
│   ├── Verify cx-llm + Ollama integration
│   ├── Create cx CLI demo
│   └── Record demo GIFs
├── Sprint 5: GPU + Branding
│   ├── Test NVIDIA/AMD driver packages
│   ├── Verify full branding pipeline
│   └── Write getting-started docs
└── Sprint 6: Security Baseline
    ├── SBOM generation
    ├── GPG verification
    └── Basic CVE scan

PHASE 3: "Make It Production-Grade" (Target: v1.1 by June 29)
├── Additional packages (cx-ops, cx-stacks, cx-secops)
├── Server meta-package + ISO variant
├── Calamares installer evaluation
├── Recovery/safe mode boot options
└── Enterprise preseed templates
```

---

## Section 5: Key Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Anshgrover23 is assigned to 6 of 7 actionable issues** | Single point of failure, bandwidth bottleneck | Distribute work; at minimum unblock Issue #54 (CI) and #55 (cx-core publish) in parallel |
| **v1.0 MVP milestone at 0% with 7 weeks to deadline** | March 30 deadline at risk | Focus exclusively on Tier 1 items; defer everything else |
| **57 mods untested as a cohesive system** | ISO may build but produce a broken desktop | Need a full integration test on real/virtual hardware |
| **No published packages yet** | Can't validate the user experience at all | This is the #1 blocker - prioritize Issue #55 above all else |
| **Domain/naming inconsistency (cortex vs cx)** | Confusing public-facing branding | Merge PRs #60, #61, #62 immediately |
| **Closed issues (#11-#20) may not reflect working features** | Features were "closed" on Jan 15 but may just be design/planning closures | Verify each closed feature actually works in the current build |

---

## Section 6: Minimum Marketable Product (MMP) Checklist

Before marketing begins, verify each item with a pass/fail:

- [ ] `apt install cx-core` works on clean Ubuntu 24.04
- [ ] `apt install cx-full` works on clean Ubuntu 24.04
- [ ] ISO downloads from GitHub Releases
- [ ] ISO boots in UEFI mode
- [ ] ISO boots in Legacy BIOS mode
- [ ] Installer completes without errors
- [ ] First-boot wizard runs
- [ ] CX Linux branding appears (GRUB, Plymouth, Desktop)
- [ ] `cx` CLI runs and responds
- [ ] At least one demo GIF/video exists
- [ ] README accurately describes how to download and install
- [ ] SHA256 checksums published alongside ISO
- [ ] GPG signatures verify correctly
- [ ] Domain references consistently point to cxlinux.ai

---

_This plan prioritizes shipping a working, installable distro over feature completeness. Marketing can begin once the MMP checklist passes. Everything in Tier 3+ can be iterated post-launch._
