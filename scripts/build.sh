#!/bin/bash
# Cortex Linux Build Script
# Called by Makefile to handle all build operations
# Copyright 2025 AI Venture Holdings LLC
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."

# Directories
BUILD_DIR="${PROJECT_ROOT}/build"
OUTPUT_DIR="${PROJECT_ROOT}/output"
ISO_DIR="${PROJECT_ROOT}/iso"
PRESEED_DIR="${ISO_DIR}/preseed"
PROVISION_DIR="${ISO_DIR}/provisioning"
PACKAGES_DIR="${PROJECT_ROOT}/packages"

# Defaults
ARCH="${ARCH:-amd64}"
DEBIAN_VERSION="${DEBIAN_VERSION:-bookworm}"
ISO_NAME="${ISO_NAME:-cortex-linux}"
ISO_VERSION="${ISO_VERSION:-$(date +%Y%m%d)}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# Logging
# =============================================================================

log() { echo -e "${GREEN}[BUILD]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header() { echo -e "\n${BLUE}=== $* ===${NC}\n"; }
pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; }

# =============================================================================
# Helper Functions
# =============================================================================

copy_if_exists() {
    local src="$1"
    local dest="$2"
    if [ -e "$src" ]; then
        cp -r "$src" "$dest"
        return 0
    fi
    return 1
}

copy_glob_if_exists() {
    local pattern="$1"
    local dest="$2"
    # shellcheck disable=SC2086
    if ls $pattern 1>/dev/null 2>&1; then
        cp $pattern "$dest"
        return 0
    fi
    return 1
}

check_command() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        log "$cmd: OK"
        return 0
    else
        error "$cmd not installed. Install with: sudo apt install $pkg"
        return 1
    fi
}

# =============================================================================
# Dependency Checking
# =============================================================================

cmd_check_deps() {
    local failed=0

    header "Checking build dependencies"

    # Required dependencies
    check_command lb live-build || failed=1
    check_command gpg gnupg || failed=1
    check_command python3 python3 || failed=1

    # Check live-build version
    if command -v lb &>/dev/null; then
        local lb_version
        lb_version=$(dpkg-query -W -f='${Version}' live-build 2>/dev/null || echo "0")
        if dpkg --compare-versions "$lb_version" lt "1:20210814"; then
            warn "live-build version $lb_version may be too old. Recommended: >= 1:20210814"
        else
            log "live-build version: $lb_version"
        fi
    fi

    # Check Python version
    if command -v python3 &>/dev/null; then
        if python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)" 2>/dev/null; then
            log "Python version: $(python3 --version 2>&1 | cut -d' ' -f2)"
        else
            warn "Python 3.11+ recommended (found: $(python3 --version 2>&1 | cut -d' ' -f2))"
        fi
    fi

    # Optional dependencies
    echo ""
    log "Checking optional dependencies..."

    if command -v shellcheck &>/dev/null; then
        log "shellcheck: OK"
    else
        warn "shellcheck not installed (optional, for linting)"
    fi

    if command -v convert &>/dev/null; then
        log "ImageMagick: OK"
    else
        warn "ImageMagick not installed (optional, for GRUB theme images)"
    fi

    if command -v dpkg-deb &>/dev/null; then
        log "dpkg-deb: OK"
    else
        warn "dpkg-deb not installed (needed for branding-package)"
    fi

    echo ""
    if [ $failed -eq 0 ]; then
        log "All required dependencies found."
        return 0
    else
        error "Missing required dependencies."
        return 1
    fi
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_preseed() {
    log "Validating preseed files..."
    local found=0
    local warnings=0

    for dir in "$PRESEED_DIR" "$PRESEED_DIR/profiles" "$PRESEED_DIR/partitioning"; do
        if [ -d "$dir" ]; then
            for f in "$dir"/*.preseed; do
                if [ -f "$f" ]; then
                    found=$((found + 1))
                    if grep -qE '^[^#]*[[:space:]]$' "$f"; then
                        warn "  $f: trailing whitespace"
                        warnings=$((warnings + 1))
                    fi
                fi
            done
        fi
    done

    if [ $found -eq 0 ]; then
        warn "No preseed files found"
    else
        log "Checked $found preseed files ($warnings warnings)"
    fi
}

validate_provision() {
    log "Validating provisioning scripts..."
    local errors=0

    if [ -f "${PROVISION_DIR}/first-boot.sh" ]; then
        if bash -n "${PROVISION_DIR}/first-boot.sh"; then
            pass "first-boot.sh: syntax OK"
        else
            fail "first-boot.sh: SYNTAX ERROR"
            errors=$((errors + 1))
        fi
    else
        warn "first-boot.sh not found"
    fi

    for script in "${PROVISION_DIR}"/*.sh; do
        if [ -f "$script" ] && [ "$(basename "$script")" != "first-boot.sh" ]; then
            if bash -n "$script"; then
                pass "$(basename "$script"): syntax OK"
            else
                fail "$(basename "$script"): SYNTAX ERROR"
                errors=$((errors + 1))
            fi
        fi
    done

    return $errors
}

validate_hooks() {
    log "Validating live-build hooks..."
    local hooks_dir="${ISO_DIR}/live-build/config/hooks/live"
    local errors=0

    if [ -d "$hooks_dir" ]; then
        for hook in "$hooks_dir"/*.hook.chroot "$hooks_dir"/*.hook.binary; do
            if [ -f "$hook" ]; then
                if bash -n "$hook"; then
                    pass "$(basename "$hook"): syntax OK"
                else
                    fail "$(basename "$hook"): SYNTAX ERROR"
                    errors=$((errors + 1))
                fi
            fi
        done
    else
        warn "Hooks directory not found"
    fi

    return $errors
}

run_shellcheck() {
    log "Running shellcheck..."

    if ! command -v shellcheck &>/dev/null; then
        warn "shellcheck not installed, skipping"
        return 0
    fi

    local errors=0

    # Check provisioning scripts
    for script in "${PROVISION_DIR}"/*.sh; do
        if [ -f "$script" ]; then
            if shellcheck "$script" 2>/dev/null; then
                pass "$(basename "$script"): OK"
            else
                fail "$(basename "$script"): issues found"
                errors=$((errors + 1))
            fi
        fi
    done

    # Check build script itself
    if shellcheck "${SCRIPT_DIR}/build.sh" 2>/dev/null; then
        pass "build.sh: OK"
    else
        fail "build.sh: issues found"
        errors=$((errors + 1))
    fi

    return $errors
}

cmd_validate() {
    local mode="${1:-all}"
    local errors=0

    header "Validation"

    case "$mode" in
        preseed)
            validate_preseed
            ;;
        provision)
            validate_provision || errors=$((errors + $?))
            ;;
        hooks)
            validate_hooks || errors=$((errors + $?))
            ;;
        lint)
            run_shellcheck || errors=$((errors + $?))
            ;;
        all)
            validate_preseed
            echo ""
            validate_provision || errors=$((errors + $?))
            echo ""
            validate_hooks || errors=$((errors + $?))
            echo ""
            run_shellcheck || errors=$((errors + $?))
            ;;
        *)
            error "Unknown validation mode: $mode"
            return 1
            ;;
    esac

    echo ""
    if [ $errors -eq 0 ]; then
        log "All validation checks passed."
    else
        error "Validation completed with errors"
        return 1
    fi
}

# =============================================================================
# Test Functions
# =============================================================================

cmd_test() {
    local errors=0

    header "Running Test Suite"

    # Test preseed file exists
    log "Testing preseed files..."
    if [ -f "${PRESEED_DIR}/cortex.preseed" ]; then
        pass "cortex.preseed: found"
    else
        fail "cortex.preseed: MISSING"
        errors=$((errors + 1))
    fi

    echo ""

    # Test provisioning scripts
    log "Testing provisioning scripts..."
    if [ -f "${PROVISION_DIR}/first-boot.sh" ]; then
        if bash -n "${PROVISION_DIR}/first-boot.sh"; then
            pass "first-boot.sh: syntax OK"
        else
            fail "first-boot.sh: SYNTAX ERROR"
            errors=$((errors + 1))
        fi
    else
        fail "first-boot.sh: NOT FOUND"
        errors=$((errors + 1))
    fi

    echo ""

    # Test branding package assets
    log "Testing branding package assets..."
    local pkg_branding="${PACKAGES_DIR}/cortex-branding"
    local required_files=(
        "boot/grub/themes/cortex/theme.txt"
        "usr/share/cortex/templates/os-release"
        "usr/share/cortex/templates/lsb-release"
        "usr/share/plymouth/themes/cortex/cortex.plymouth"
    )

    for file in "${required_files[@]}"; do
        if [ -f "${pkg_branding}/${file}" ]; then
            pass "${file}: found"
        else
            fail "${file}: MISSING"
            errors=$((errors + 1))
        fi
    done

    echo ""

    # Test hooks
    log "Testing live-build hooks..."
    local hooks_dir="${ISO_DIR}/live-build/config/hooks/live"
    for hook in "$hooks_dir"/*.hook.chroot; do
        if [ -f "$hook" ]; then
            if bash -n "$hook"; then
                pass "$(basename "$hook"): syntax OK"
            else
                fail "$(basename "$hook"): SYNTAX ERROR"
                errors=$((errors + 1))
            fi
        fi
    done

    echo ""

    # Test package control files (debian/ source format)
    log "Testing package control files..."
    local pkg_dir="${PACKAGES_DIR}/cortex-branding/debian"
    for file in control postinst prerm rules; do
        if [ -f "${pkg_dir}/${file}" ]; then
            pass "debian/${file}: found"
            if [[ "$file" == "postinst" || "$file" == "prerm" ]]; then
                if bash -n "${pkg_dir}/${file}"; then
                    pass "debian/${file}: syntax OK"
                else
                    fail "debian/${file}: SYNTAX ERROR"
                    errors=$((errors + 1))
                fi
            fi
        else
            fail "debian/${file}: MISSING"
            errors=$((errors + 1))
        fi
    done

    echo ""
    echo "========================"
    if [ $errors -eq 0 ]; then
        log "All tests passed!"
        return 0
    else
        error "Tests completed with ${errors} error(s)"
        return 1
    fi
}

# =============================================================================
# ISO Build Functions
# =============================================================================

prepare_build_dir() {
    header "Preparing build directory"

    mkdir -p "${BUILD_DIR}/config/package-lists"
    mkdir -p "${BUILD_DIR}/config/hooks/live"

    # Copy package lists
    if copy_glob_if_exists "${ISO_DIR}/live-build/config/package-lists/*.list.chroot" "${BUILD_DIR}/config/package-lists/"; then
        log "Copied package lists"
    fi

    # Copy hooks
    if [ -d "${ISO_DIR}/live-build/config/hooks" ]; then
        cp -r "${ISO_DIR}/live-build/config/hooks" "${BUILD_DIR}/config/"
        log "Copied hooks"
    fi

    # Copy includes.chroot (use -rL to follow symlinks and copy actual content)
    if [ -d "${ISO_DIR}/live-build/config/includes.chroot" ]; then
        # Remove target first to avoid conflicts with symlinks
        rm -rf "${BUILD_DIR}/config/includes.chroot"
        cp -rL "${ISO_DIR}/live-build/config/includes.chroot" "${BUILD_DIR}/config/"
        log "Copied includes.chroot (symlinks dereferenced)"
    fi

    # Copy includes.binary
    if [ -d "${ISO_DIR}/live-build/config/includes.binary" ]; then
        cp -r "${ISO_DIR}/live-build/config/includes.binary" "${BUILD_DIR}/config/"
        log "Copied includes.binary"
    fi

    # Copy bootloaders
    if [ -d "${ISO_DIR}/live-build/config/bootloaders" ]; then
        cp -r "${ISO_DIR}/live-build/config/bootloaders" "${BUILD_DIR}/config/"
        log "Copied bootloaders"
    fi

    # Copy local .deb packages (packages.chroot)
    if [ -d "${ISO_DIR}/live-build/config/packages.chroot" ]; then
        mkdir -p "${BUILD_DIR}/config/packages.chroot"
        # Copy any existing .deb files (excluding .gitkeep)
        if ls "${ISO_DIR}/live-build/config/packages.chroot"/*.deb 1>/dev/null 2>&1; then
            cp "${ISO_DIR}/live-build/config/packages.chroot"/*.deb "${BUILD_DIR}/config/packages.chroot/"
            log "Copied local .deb packages from packages.chroot"
        fi
    fi
}

copy_grub_theme() {
    local theme_dest="${BUILD_DIR}/config/bootloaders/grub-pc/live-theme"
    local theme_src="${PACKAGES_DIR}/cortex-branding/boot/grub/themes/cortex"

    header "Copying GRUB theme from package"

    mkdir -p "$theme_dest"

    # Copy all theme files from package
    if [ -d "$theme_src" ]; then
        cp -r "$theme_src"/* "$theme_dest/"
        log "Copied GRUB theme files"
    else
        error "GRUB theme not found in ${theme_src}"
        exit 1
    fi

    # Convert background to 8-bit for GRUB compatibility
    if command -v convert &>/dev/null && [ -f "${theme_dest}/background.png" ]; then
        convert "${theme_dest}/background.png" -depth 8 -type TrueColor \
            "PNG24:${theme_dest}/background.png"
        log "Converted background.png to 8-bit for GRUB"
    fi
}

configure_live_build() {
    header "Configuring live-build"

    cd "$BUILD_DIR"

    # Use lz4 compression for faster builds (CI), xz for release builds
    # lz4: ~2-3 min vs xz: ~20 min, but ISO is ~20% larger
    local compression="${SQUASHFS_COMP:-lz4}"

    # Check if apt-cacher-ng is running locally for package caching
    local mirror_bootstrap="http://deb.debian.org/debian"
    local mirror_chroot="http://deb.debian.org/debian"
    local mirror_binary="http://deb.debian.org/debian"
    
    if curl -s --connect-timeout 2 http://localhost:3142 >/dev/null 2>&1; then
        log "apt-cacher-ng detected, using local cache proxy"
        mirror_bootstrap="http://localhost:3142/deb.debian.org/debian"
        mirror_chroot="http://localhost:3142/deb.debian.org/debian"
        mirror_binary="http://deb.debian.org/debian"  # Keep binary mirror direct for ISO
    else
        warn "apt-cacher-ng not running, using direct mirrors (slower)"
    fi

    lb config \
        --distribution "$DEBIAN_VERSION" \
        --archive-areas "main contrib non-free non-free-firmware" \
        --architectures "$ARCH" \
        --binary-images iso-hybrid \
        --bootappend-live "boot=live components username=cortex quiet splash vt.handoff=7 loglevel=3 plymouth.ignore-serial-consoles preseed/file=/cdrom/preseed/cortex.preseed" \
        --debian-installer live \
        --debian-installer-gui false \
        --iso-application "Cortex Linux" \
        --iso-publisher "AI Venture Holdings LLC" \
        --iso-volume "CORTEX_LINUX" \
        --mirror-bootstrap "$mirror_bootstrap" \
        --mirror-chroot "$mirror_chroot" \
        --mirror-binary "$mirror_binary" \
        --cache true \
        --cache-packages true \
        --cache-indices false \
        --cache-stages bootstrap \
        --chroot-squashfs-compression-type "$compression"

    log "Live-build configured (compression: ${compression})"
}

copy_preseed_files() {
    local preseed_dest="${BUILD_DIR}/config/includes.binary/preseed"

    header "Copying preseed and provisioning files"

    mkdir -p "$preseed_dest"
    mkdir -p "${BUILD_DIR}/config/includes.binary/provisioning"

    # Copy preseed files
    if copy_glob_if_exists "${PRESEED_DIR}/*.preseed" "$preseed_dest/"; then
        log "Copied preseed files"
    fi

    # Copy provisioning files (use -r for directories)
    if [ -d "$PROVISION_DIR" ]; then
        cp -r "${PROVISION_DIR}"/* "${BUILD_DIR}/config/includes.binary/provisioning/" 2>/dev/null || true
        log "Copied provisioning files"
    fi
}

build_iso() {
    header "Building ISO"

    cd "$BUILD_DIR"

    # Clean binary stage markers to ensure ISO creation runs fresh
    # This prevents stale markers from causing lb build to skip the binary_iso stage
    if [ -d ".build" ]; then
        log "Cleaning binary stage markers..."
        sudo rm -f .build/binary_* 2>/dev/null || true
    fi

    log "Starting live-build (this may take a while)..."
    sudo lb build

    log "Build complete"
}

move_output() {
    local iso_file="${BUILD_DIR}/live-image-${ARCH}.hybrid.iso"
    local output_name="${ISO_NAME}-${ISO_VERSION}-${ARCH}.iso"

    header "Moving output"

    mkdir -p "$OUTPUT_DIR"

    if [ -f "$iso_file" ]; then
        mv "$iso_file" "${OUTPUT_DIR}/${output_name}"
        log "ISO built: ${OUTPUT_DIR}/${output_name}"

        # Generate checksums
        cd "$OUTPUT_DIR"
        sha256sum "$output_name" > "${output_name}.sha256"
        log "Checksum generated: ${output_name}.sha256"
    else
        error "ISO file not found at ${iso_file}"
        exit 1
    fi
}

generate_sbom() {
    header "Generating SBOM"

    if [ -f "${PROJECT_ROOT}/sbom/generate-sbom.sh" ]; then
        chmod +x "${PROJECT_ROOT}/sbom/generate-sbom.sh"
        "${PROJECT_ROOT}/sbom/generate-sbom.sh" "${OUTPUT_DIR}/sbom"
        log "SBOM generated: ${OUTPUT_DIR}/sbom/"
    else
        warn "SBOM generator not found at sbom/generate-sbom.sh"
    fi
}

build_local_packages() {
    header "Building local packages for ISO"

    # Ensure output directory exists
    mkdir -p "$OUTPUT_DIR"

    # Build packages needed for ISO (cortex-branding is required)
    # Add more packages here as needed
    local iso_packages="cortex-branding"
    local build_failed=0

    for pkg in $iso_packages; do
        log "Building ${pkg}..."
        if ! build_single_package "$pkg"; then
            error "Failed to build ${pkg} - this package is required for ISO"
            build_failed=1
        fi
    done

    # Fail early if required packages didn't build
    if [ "$build_failed" -eq 1 ]; then
        error "Required package(s) failed to build. Aborting ISO build."
        exit 1
    fi

    # Copy built packages to packages.chroot for ISO inclusion
    local pkg_dest="${BUILD_DIR}/config/packages.chroot"
    mkdir -p "$pkg_dest"

    if ls "${OUTPUT_DIR}"/*.deb 1>/dev/null 2>&1; then
        cp "${OUTPUT_DIR}"/*.deb "$pkg_dest/"
        log "Copied packages to packages.chroot:"
        ls -la "$pkg_dest"/*.deb 2>/dev/null || true
    else
        error "No .deb packages found in ${OUTPUT_DIR} - cannot continue"
        exit 1
    fi
}

cmd_build() {
    header "Building Cortex Linux ISO"
    log "Architecture: ${ARCH}"
    log "Debian version: ${DEBIAN_VERSION}"

    prepare_build_dir
    build_local_packages
    copy_grub_theme
    configure_live_build
    copy_preseed_files
    build_iso
    move_output
    generate_sbom

    header "Build Complete"
    log "Output: ${OUTPUT_DIR}/"
}

# =============================================================================
# Clean Functions
# =============================================================================

cmd_clean() {
    header "Cleaning build"

    if [ -d "$BUILD_DIR" ]; then
        cd "$BUILD_DIR"
        sudo lb clean
        
        # Clean local package caches (prevents hash mismatch when packages are rebuilt)
        # lb clean doesn't touch cache/ for speed, but we need fresh package indices
        log "Cleaning local package caches..."
        sudo rm -rf cache/packages.chroot 2>/dev/null || true
        
        log "Clean complete"
    else
        warn "Build directory not found: ${BUILD_DIR}"
    fi
}

cmd_clean_all() {
    header "Cleaning all build artifacts"

    rm -rf "$BUILD_DIR"
    rm -rf "$OUTPUT_DIR"

    log "Full clean complete"
}

cmd_clean_hooks() {
    header "Cleaning hook markers"

    if [ -d "${BUILD_DIR}/.build" ]; then
        rm -f "${BUILD_DIR}/.build/chroot_hooks"
        rm -f "${BUILD_DIR}/.build/binary_hooks"
        log "Cleaned hook markers"
    fi

    log "Hooks will re-run on next build"
}

# =============================================================================
# Sync Functions
# =============================================================================

cmd_sync() {
    header "Syncing config"

    if [ -d "$BUILD_DIR" ]; then
        [ -d "${ISO_DIR}/live-build/config/hooks" ] && \
            cp -r "${ISO_DIR}/live-build/config/hooks" "${BUILD_DIR}/config/"
        # Use -rL to follow symlinks and copy actual content
        if [ -d "${ISO_DIR}/live-build/config/includes.chroot" ]; then
            rm -rf "${BUILD_DIR}/config/includes.chroot"
            cp -rL "${ISO_DIR}/live-build/config/includes.chroot" "${BUILD_DIR}/config/"
        fi
        [ -d "${ISO_DIR}/live-build/config/includes.binary" ] && \
            cp -r "${ISO_DIR}/live-build/config/includes.binary" "${BUILD_DIR}/config/"
        log "Config synced (symlinks dereferenced)"
    else
        warn "Build directory not found: ${BUILD_DIR}"
    fi
}

# =============================================================================
# Package Building Functions
# =============================================================================

# List of available packages (add new packages here)
AVAILABLE_PACKAGES="cortex-branding"

# Get package version from DEBIAN/control or debian/changelog
get_package_version() {
    local pkg_name="$1"
    local pkg_path="${PACKAGES_DIR}/${pkg_name}"
    
    # Try DEBIAN/control first (binary package format)
    if [ -f "${pkg_path}/DEBIAN/control" ]; then
        grep -E "^Version:" "${pkg_path}/DEBIAN/control" | awk '{print $2}' | head -1
        return
    fi
    
    # Try debian/changelog (source package format)
    if [ -f "${pkg_path}/debian/changelog" ]; then
        head -1 "${pkg_path}/debian/changelog" | grep -oP '\(.*?\)' | tr -d '()'
        return
    fi
    
    # Default version
    echo "1.0.0"
}

# Get package architecture from DEBIAN/control
get_package_arch() {
    local pkg_name="$1"
    local pkg_path="${PACKAGES_DIR}/${pkg_name}"
    
    if [ -f "${pkg_path}/DEBIAN/control" ]; then
        grep -E "^Architecture:" "${pkg_path}/DEBIAN/control" | awk '{print $2}' | head -1
        return
    fi
    
    if [ -f "${pkg_path}/debian/control" ]; then
        grep -E "^Architecture:" "${pkg_path}/debian/control" | awk '{print $2}' | head -1
        return
    fi
    
    echo "all"
}

# Build cortex-branding package using dpkg-buildpackage
# The package is self-contained with all assets in packages/cortex-branding/
build_pkg_cortex_branding() {
    local pkg_name="cortex-branding"
    local pkg_path="${PACKAGES_DIR}/${pkg_name}"

    log "Building ${pkg_name} (self-contained package)..."

    if [ ! -d "${pkg_path}/debian" ]; then
        error "${pkg_name} has no debian/ directory"
        return 1
    fi

    # Build using dpkg-buildpackage
    cd "$pkg_path"
    
    # Clean any previous build artifacts
    rm -f ../${pkg_name}_*.deb ../${pkg_name}_*.changes ../${pkg_name}_*.buildinfo 2>/dev/null || true
    
    if dpkg-buildpackage -us -uc -b; then
        # Move built packages to output
        mv ../${pkg_name}_*.deb "${OUTPUT_DIR}/" 2>/dev/null || true
        mv ../${pkg_name}_*.changes "${OUTPUT_DIR}/" 2>/dev/null || true
        mv ../${pkg_name}_*.buildinfo "${OUTPUT_DIR}/" 2>/dev/null || true
        
        cd "$PROJECT_ROOT"
        log "Built: ${pkg_name} -> ${OUTPUT_DIR}/"
    else
        cd "$PROJECT_ROOT"
        error "dpkg-buildpackage failed for ${pkg_name}"
        return 1
    fi
}

# Build a meta-package using dpkg-buildpackage (for packages with debian/ dir)
# Falls back to generic DEBIAN/ build if no debian/ dir
build_meta_package() {
    local pkg_name="$1"
    local pkg_path="${PACKAGES_DIR}/${pkg_name}"

    log "Building ${pkg_name}..."

    # Try debian/ source format first
    if [ -d "${pkg_path}/debian" ]; then
        cd "$pkg_path"
        if dpkg-buildpackage -us -uc -b 2>/dev/null; then
            mv ../"${pkg_name}"_*.deb "${OUTPUT_DIR}/" 2>/dev/null || true
            mv ../"${pkg_name}"_*.changes "${OUTPUT_DIR}/" 2>/dev/null || true
            mv ../"${pkg_name}"_*.buildinfo "${OUTPUT_DIR}/" 2>/dev/null || true
            cd "$PROJECT_ROOT"
            log "Built: ${pkg_name}"
            return 0
        fi
        cd "$PROJECT_ROOT"
    fi

    # Fall back to DEBIAN/ binary format
    if [ -d "${pkg_path}/DEBIAN" ]; then
        build_generic_package "$pkg_name"
        return $?
    fi

    warn "${pkg_name} has no debian/ or DEBIAN/ directory, skipping"
    return 0
}

# Build cortex-core package (meta-package)
build_pkg_cortex_core() {
    build_meta_package "cortex-core"
}

# Build cortex-full package (meta-package)
build_pkg_cortex_full() {
    build_meta_package "cortex-full"
}

# Build cortex-secops package (meta-package)
build_pkg_cortex_secops() {
    build_meta_package "cortex-secops"
}

# Build a single package by name
build_single_package() {
    local pkg_name="$1"
    
    # Check if package exists
    if [ ! -d "${PACKAGES_DIR}/${pkg_name}" ]; then
        error "Package not found: ${pkg_name}"
        error "Available packages: ${AVAILABLE_PACKAGES}"
        return 1
    fi

    # Call the appropriate build function
    local build_func="build_pkg_${pkg_name//-/_}"
    if declare -f "$build_func" > /dev/null; then
        "$build_func"
    else
        # Generic build for packages with DEBIAN/ directory
        build_generic_package "$pkg_name"
    fi
}

# Generic package builder for simple packages
build_generic_package() {
    local pkg_name="$1"
    local pkg_version
    pkg_version=$(get_package_version "$pkg_name")
    local pkg_arch
    pkg_arch=$(get_package_arch "$pkg_name")
    local pkg_dir="${BUILD_DIR}/${pkg_name}"
    local pkg_path="${PACKAGES_DIR}/${pkg_name}"

    log "Building ${pkg_name} v${pkg_version} (generic)..."

    # Check for DEBIAN directory
    if [ ! -d "${pkg_path}/DEBIAN" ]; then
        warn "${pkg_name} has no DEBIAN/ directory, skipping"
        return 0
    fi

    # Create package directory
    mkdir -p "${pkg_dir}"
    
    # Copy everything except debian/ and DEBIAN/
    find "${pkg_path}" -mindepth 1 -maxdepth 1 ! -name "debian" ! -name "DEBIAN" -exec cp -r {} "${pkg_dir}/" \;
    
    # Copy DEBIAN control files
    mkdir -p "${pkg_dir}/DEBIAN"
    cp "${pkg_path}/DEBIAN/"* "${pkg_dir}/DEBIAN/"
    
    # Make maintainer scripts executable
    for script in postinst prerm postrm preinst; do
        [ -f "${pkg_dir}/DEBIAN/${script}" ] && chmod 755 "${pkg_dir}/DEBIAN/${script}"
    done

    # Build the package
    local output_file="${OUTPUT_DIR}/${pkg_name}_${pkg_version}_${pkg_arch}.deb"
    dpkg-deb --build "$pkg_dir" "$output_file"
    rm -rf "$pkg_dir"

    log "Built: ${output_file}"
}

# Main package build command
cmd_build_package() {
    local target="${1:-all}"
    
    header "Building Packages"
    mkdir -p "$OUTPUT_DIR"

    if [ "$target" = "all" ]; then
        log "Building all packages..."
        for pkg in $AVAILABLE_PACKAGES; do
            if [ -d "${PACKAGES_DIR}/${pkg}" ]; then
                build_single_package "$pkg" || warn "Failed to build ${pkg}"
            fi
        done
    else
        build_single_package "$target"
    fi

    echo ""
    log "Packages in ${OUTPUT_DIR}:"
    ls -la "${OUTPUT_DIR}"/*.deb 2>/dev/null || echo "  (none)"
}


# =============================================================================
# Help
# =============================================================================

cmd_help() {
    cat << EOF
Cortex Linux Build Script

Usage: $0 <command> [args]

Build Commands:
    build                   Build Cortex Linux ISO
    build-package [name]    Build .deb packages (default: all)
                            Available: ${AVAILABLE_PACKAGES}

Validation Commands:
    check-deps              Check build dependencies
    validate [mode]         Run validation (all|preseed|provision|hooks|lint)
    test                    Run test suite

Clean Commands:
    clean                   Clean build artifacts
    clean-all               Clean all build artifacts and output
    clean-hooks             Clean hook markers for re-run

Utility Commands:
    sync                    Sync config files to build directory
    help                    Show this help

Environment Variables:
    ARCH                    Architecture (default: amd64)
    DEBIAN_VERSION          Debian version (default: bookworm)
    ISO_NAME                ISO name prefix (default: cortex-linux)
    ISO_VERSION             ISO version (default: YYYYMMDD)

Examples:
    $0 build                        # Build ISO
    ARCH=arm64 $0 build             # Build ARM64 ISO
    $0 build-package                # Build all packages
    $0 build-package cortex-branding  # Build only cortex-branding
    $0 validate
    $0 test
    $0 clean-all
EOF
}

# =============================================================================
# Entry Point
# =============================================================================

main() {
    local cmd="${1:-help}"
    shift || true

    case "$cmd" in
        build)
            cmd_build "$@"
            ;;
        check-deps)
            cmd_check_deps
            ;;
        validate)
            cmd_validate "$@"
            ;;
        test)
            cmd_test
            ;;
        clean)
            cmd_clean "$@"
            ;;
        clean-all)
            cmd_clean_all
            ;;
        clean-hooks)
            cmd_clean_hooks
            ;;
        sync)
            cmd_sync "$@"
            ;;
        build-package|package|branding-package)
            cmd_build_package "$@"
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            error "Unknown command: $cmd"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
