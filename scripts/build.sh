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
BRANDING_DIR="${PROJECT_ROOT}/branding"
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

    # Check branding install script
    if [ -f "${BRANDING_DIR}/install-branding.sh" ]; then
        if shellcheck "${BRANDING_DIR}/install-branding.sh" 2>/dev/null; then
            pass "install-branding.sh: OK"
        else
            fail "install-branding.sh: issues found"
            errors=$((errors + 1))
        fi
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

    # Test branding assets
    log "Testing branding assets..."
    local required_files=(
        "grub/cortex/theme.txt"
        "os-release/os-release"
        "os-release/lsb-release"
    )

    for file in "${required_files[@]}"; do
        if [ -f "${BRANDING_DIR}/${file}" ]; then
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

    # Test package control files
    log "Testing package control files..."
    local pkg_dir="${PACKAGES_DIR}/cortex-branding/DEBIAN"
    for file in control postinst prerm; do
        if [ -f "${pkg_dir}/${file}" ]; then
            pass "DEBIAN/${file}: found"
            if [[ "$file" == "postinst" || "$file" == "prerm" ]]; then
                if bash -n "${pkg_dir}/${file}"; then
                    pass "DEBIAN/${file}: syntax OK"
                else
                    fail "DEBIAN/${file}: SYNTAX ERROR"
                    errors=$((errors + 1))
                fi
            fi
        else
            fail "DEBIAN/${file}: MISSING"
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

    # Copy includes.chroot
    if [ -d "${ISO_DIR}/live-build/config/includes.chroot" ]; then
        cp -r "${ISO_DIR}/live-build/config/includes.chroot" "${BUILD_DIR}/config/"
        log "Copied includes.chroot"
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
}

copy_grub_theme() {
    local theme_dest="${BUILD_DIR}/config/bootloaders/grub-pc/live-theme"

    header "Copying GRUB theme from branding"

    mkdir -p "$theme_dest"

    # Copy PNG files
    if copy_glob_if_exists "${BRANDING_DIR}/grub/cortex/*.png" "$theme_dest/"; then
        log "Copied PNG files"
    fi

    # Copy theme.txt (required)
    if [ -f "${BRANDING_DIR}/grub/cortex/theme.txt" ]; then
        cp "${BRANDING_DIR}/grub/cortex/theme.txt" "$theme_dest/"
        log "Copied theme.txt"
    else
        error "theme.txt not found in ${BRANDING_DIR}/grub/cortex/"
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

    lb config \
        --distribution "$DEBIAN_VERSION" \
        --archive-areas "main contrib non-free non-free-firmware" \
        --architectures "$ARCH" \
        --binary-images iso-hybrid \
        --bootappend-live "boot=live components username=cortex splash quiet preseed/file=/cdrom/preseed/cortex.preseed" \
        --debian-installer live \
        --debian-installer-gui false \
        --iso-application "Cortex Linux" \
        --iso-publisher "AI Venture Holdings LLC" \
        --iso-volume "CORTEX_LINUX" \
        --cache true \
        --cache-packages true \
        --cache-indices true \
        --cache-stages bootstrap

    log "Live-build configured"
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

    # Copy provisioning files
    if [ -d "$PROVISION_DIR" ]; then
        if copy_glob_if_exists "${PROVISION_DIR}/*" "${BUILD_DIR}/config/includes.binary/provisioning/"; then
            log "Copied provisioning files"
        fi
    fi
}

build_iso() {
    header "Building ISO"

    cd "$BUILD_DIR"

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

cmd_build() {
    header "Building Cortex Linux ISO"
    log "Architecture: ${ARCH}"
    log "Debian version: ${DEBIAN_VERSION}"

    prepare_build_dir
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
        [ -d "${ISO_DIR}/live-build/config/includes.chroot" ] && \
            cp -r "${ISO_DIR}/live-build/config/includes.chroot" "${BUILD_DIR}/config/"
        [ -d "${ISO_DIR}/live-build/config/includes.binary" ] && \
            cp -r "${ISO_DIR}/live-build/config/includes.binary" "${BUILD_DIR}/config/"
        log "Config synced"
    else
        warn "Build directory not found: ${BUILD_DIR}"
    fi
}

# =============================================================================
# Branding Package Functions
# =============================================================================

cmd_branding_package() {
    local pkg_name="cortex-branding"
    local pkg_version="1.0.0"
    local pkg_dir="${BUILD_DIR}/${pkg_name}"

    header "Building Cortex Branding Package"

    # Create directory structure
    log "Creating package directory structure..."
    mkdir -p "${pkg_dir}/DEBIAN"
    mkdir -p "${pkg_dir}/etc"
    mkdir -p "${pkg_dir}/usr/share/plymouth/themes/cortex"
    mkdir -p "${pkg_dir}/boot/grub/themes/cortex"
    mkdir -p "${pkg_dir}/usr/share/backgrounds/cortex"
    mkdir -p "${pkg_dir}/usr/share/gnome-background-properties"
    mkdir -p "${pkg_dir}/etc/update-motd.d"
    mkdir -p "${pkg_dir}/usr/share/cortex/logos"

    # Copy DEBIAN control files
    log "Copying DEBIAN control files..."
    if [ -d "${PACKAGES_DIR}/${pkg_name}/DEBIAN" ]; then
        cp "${PACKAGES_DIR}/${pkg_name}/DEBIAN/"* "${pkg_dir}/DEBIAN/"
        chmod 755 "${pkg_dir}/DEBIAN/postinst"
        chmod 755 "${pkg_dir}/DEBIAN/prerm"
    else
        error "DEBIAN control files not found"
        exit 1
    fi

    # Copy OS release files
    log "Copying OS release files..."
    local os_release_dir="${BRANDING_DIR}/os-release"
    if [ -d "$os_release_dir" ]; then
        copy_if_exists "${os_release_dir}/os-release" "${pkg_dir}/etc/os-release"
        copy_if_exists "${os_release_dir}/lsb-release" "${pkg_dir}/etc/lsb-release"
        copy_if_exists "${os_release_dir}/issue" "${pkg_dir}/etc/issue"
        copy_if_exists "${os_release_dir}/issue.net" "${pkg_dir}/etc/issue.net"
    fi

    # Copy Plymouth theme
    log "Copying Plymouth theme..."
    if [ -d "${BRANDING_DIR}/plymouth/cortex" ]; then
        copy_glob_if_exists "${BRANDING_DIR}/plymouth/cortex/*" "${pkg_dir}/usr/share/plymouth/themes/cortex/" || true
    fi

    # Copy GRUB theme
    log "Copying GRUB theme..."
    if [ -d "${BRANDING_DIR}/grub/cortex" ]; then
        copy_glob_if_exists "${BRANDING_DIR}/grub/cortex/*" "${pkg_dir}/boot/grub/themes/cortex/" || true

        # Convert background to 8-bit
        local bg="${pkg_dir}/boot/grub/themes/cortex/background.png"
        if command -v convert &>/dev/null && [ -f "$bg" ]; then
            convert "$bg" -depth 8 -type TrueColor "PNG24:${bg}"
            log "Converted background.png to 8-bit"
        fi
    fi

    # Copy wallpapers
    log "Copying wallpapers..."
    copy_glob_if_exists "${BRANDING_DIR}/wallpapers/*.xml" "${pkg_dir}/usr/share/gnome-background-properties/" || true
    if [ -d "${BRANDING_DIR}/wallpapers/images" ]; then
        copy_glob_if_exists "${BRANDING_DIR}/wallpapers/images/*" "${pkg_dir}/usr/share/backgrounds/cortex/" || true
    fi

    # Copy MOTD scripts
    log "Copying MOTD scripts..."
    if [ -d "${BRANDING_DIR}/motd" ]; then
        if copy_glob_if_exists "${BRANDING_DIR}/motd/*" "${pkg_dir}/etc/update-motd.d/"; then
            chmod 755 "${pkg_dir}/etc/update-motd.d/"*
        fi
    fi

    # Copy logos
    if [ -d "${BRANDING_DIR}/logos" ]; then
        copy_glob_if_exists "${BRANDING_DIR}/logos/*" "${pkg_dir}/usr/share/cortex/logos/" || true
    fi

    # Build the package
    log "Building .deb package..."
    mkdir -p "$OUTPUT_DIR"
    local output_file="${OUTPUT_DIR}/${pkg_name}_${pkg_version}_all.deb"
    dpkg-deb --build "$pkg_dir" "$output_file"

    # Cleanup
    rm -rf "$pkg_dir"

    log "Package built: ${output_file}"
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
    branding-package        Build cortex-branding .deb package

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
    $0 build
    ARCH=arm64 $0 build
    $0 validate
    $0 test
    $0 clean
    $0 clean-all
    $0 branding-package
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
        branding-package)
            cmd_branding_package
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
