#!/bin/bash
# CX Linux Ubuntu 24.04 Verification Script
# Validates Ubuntu-specific configuration and compatibility
# Copyright 2025 AI Venture Holdings LLC
# SPDX-License-Identifier: Apache-2.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[TEST]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"

    ((TESTS_RUN++))

    log "Testing: $test_name"

    if eval "$test_command"; then
        log "✅ PASS: $test_name"
        ((TESTS_PASSED++))
    else
        error "❌ FAIL: $test_name"
        ((TESTS_FAILED++))
    fi

    echo
}

# =============================================================================
# CONFIGURATION TESTS
# =============================================================================

test_ubuntu_config() {
    # Check if using Ubuntu noble (24.04)
    grep -q 'CODENAME="noble"' "${PROJECT_ROOT}/iso/live-build/auto/config"
}

test_ubuntu_mirrors() {
    # Check Ubuntu mirrors in preseed
    grep -q 'archive.ubuntu.com' "${PROJECT_ROOT}/iso/preseed/cx.preseed" && \
    grep -q 'security.ubuntu.com' "${PROJECT_ROOT}/iso/preseed/cx.preseed"
}

test_ubuntu_packages() {
    # Check Ubuntu-specific packages are included
    grep -q 'ubuntu-keyring' "${PROJECT_ROOT}/iso/live-build/auto/config" && \
    grep -q 'software-properties-common' "${PROJECT_ROOT}/iso/live-build/auto/config"
}

test_gpu_support() {
    # Check GPU support in package lists
    grep -q 'mesa-vulkan-drivers' "${PROJECT_ROOT}/iso/live-build/config/package-lists/cx-full.list.chroot" && \
    grep -q 'nvidia-detect' "${PROJECT_ROOT}/iso/live-build/config/package-lists/cx-full.list.chroot"
}

test_hook_scripts() {
    # Check hook scripts exist and are executable
    [ -x "${PROJECT_ROOT}/iso/live-build/config/hooks/live/0100-cx-config.hook.chroot" ] && \
    [ -x "${PROJECT_ROOT}/iso/live-build/config/hooks/live/0200-ubuntu-setup.hook.chroot" ]
}

test_branding_consistency() {
    # Check consistent CX Linux branding (not Cortex Linux)
    ! grep -r -i "cortex linux" "${PROJECT_ROOT}/iso/" --exclude-dir=.git && \
    grep -q "CX Linux" "${PROJECT_ROOT}/iso/live-build/config/hooks/live/0100-cx-config.hook.chroot"
}

test_firstboot_script() {
    # Check first-boot script has Ubuntu features
    [ -f "${PROJECT_ROOT}/iso/live-build/config/includes.chroot/usr/lib/cx/firstboot.sh" ] && \
    grep -q "provision_gpu_drivers" "${PROJECT_ROOT}/iso/live-build/config/includes.chroot/usr/lib/cx/firstboot.sh" && \
    grep -q "ubuntu-drivers" "${PROJECT_ROOT}/iso/live-build/config/includes.chroot/usr/lib/cx/firstboot.sh"
}

test_preseed_ubuntu() {
    # Check preseed uses Ubuntu suite
    grep -q 'noble' "${PROJECT_ROOT}/iso/preseed/cx.preseed"
}

# =============================================================================
# BUILD ENVIRONMENT TESTS
# =============================================================================

test_build_dependencies() {
    # Check if live-build is available
    command -v lb >/dev/null 2>&1
}

test_debootstrap() {
    # Check if debootstrap supports Ubuntu
    command -v debootstrap >/dev/null 2>&1 && \
    [ -f /usr/share/debootstrap/scripts/noble ] || [ -f /usr/share/debootstrap/scripts/gutsy ]
}

# =============================================================================
# RUN ALL TESTS
# =============================================================================

main() {
    log "CX Linux Ubuntu 24.04 Verification Tests"
    log "========================================"

    # Configuration tests
    run_test "Ubuntu 24.04 (noble) configuration" "test_ubuntu_config"
    run_test "Ubuntu package mirrors" "test_ubuntu_mirrors"
    run_test "Ubuntu-specific packages" "test_ubuntu_packages"
    run_test "GPU driver support" "test_gpu_support"
    run_test "Hook scripts present and executable" "test_hook_scripts"
    run_test "Consistent CX Linux branding" "test_branding_consistency"
    run_test "First-boot script Ubuntu features" "test_firstboot_script"
    run_test "Preseed Ubuntu configuration" "test_preseed_ubuntu"

    # Build environment tests
    run_test "live-build available" "test_build_dependencies"
    run_test "debootstrap Ubuntu support" "test_debootstrap"

    # Summary
    log "========================================"
    log "Tests Run: $TESTS_RUN"
    log "Passed: $TESTS_PASSED"
    log "Failed: $TESTS_FAILED"

    if [ $TESTS_FAILED -eq 0 ]; then
        log "🎉 All tests passed! Ubuntu 24.04 configuration is ready."
        exit 0
    else
        error "❌ $TESTS_FAILED tests failed. Please fix issues before building."
        exit 1
    fi
}

main "$@"