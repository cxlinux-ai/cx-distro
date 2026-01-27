#!/bin/bash
# GitHub Actions Workflow Verification Script
# Validates the build-iso.yml workflow configuration
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
# WORKFLOW FILE TESTS
# =============================================================================

test_workflow_exists() {
    [ -f "${PROJECT_ROOT}/.github/workflows/build-iso.yml" ]
}

test_workflow_ubuntu_runner() {
    grep -q "runs-on: ubuntu-24.04" "${PROJECT_ROOT}/.github/workflows/build-iso.yml"
}

test_workflow_triggers() {
    grep -q "push:" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
    grep -q "branches: \[ main \]" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
    grep -q "workflow_dispatch:" "${PROJECT_ROOT}/.github/workflows/build-iso.yml"
}

test_workflow_make_commands() {
    grep -q "make deps" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
    grep -q "make package" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
    grep -q "make iso" "${PROJECT_ROOT}/.github/workflows/build-iso.yml"
}

test_workflow_artifacts() {
    grep -q "upload-artifact@v4" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
    grep -q "cx-linux-" "${PROJECT_ROOT}/.github/workflows/build-iso.yml"
}

test_workflow_build_types() {
    grep -q "offline" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
    grep -q "netinst" "${PROJECT_ROOT}/.github/workflows/build-iso.yml"
}

test_workflow_timeout() {
    grep -q "timeout-minutes: 120" "${PROJECT_ROOT}/.github/workflows/build-iso.yml"
}

test_workflow_disk_cleanup() {
    grep -q "Free up disk space" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
    grep -q "/usr/share/dotnet" "${PROJECT_ROOT}/.github/workflows/build-iso.yml"
}

test_workflow_caching() {
    grep -q "uses: actions/cache@v4" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
    grep -q "live-build" "${PROJECT_ROOT}/.github/workflows/build-iso.yml"
}

test_workflow_releases() {
    grep -q "create-release" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
    grep -q "softprops/action-gh-release" "${PROJECT_ROOT}/.github/workflows/build-iso.yml"
}

# =============================================================================
# MAKEFILE COMPATIBILITY TESTS
# =============================================================================

test_makefile_targets() {
    grep -q "iso:" "${PROJECT_ROOT}/Makefile" && \
    grep -q "iso-offline:" "${PROJECT_ROOT}/Makefile" && \
    grep -q "iso-netinst:" "${PROJECT_ROOT}/Makefile" && \
    grep -q "deps:" "${PROJECT_ROOT}/Makefile" && \
    grep -q "package:" "${PROJECT_ROOT}/Makefile"
}

test_makefile_ubuntu() {
    grep -q "noble" "${PROJECT_ROOT}/Makefile"
}

# =============================================================================
# DIRECTORY STRUCTURE TESTS
# =============================================================================

test_github_directory() {
    [ -d "${PROJECT_ROOT}/.github" ] && \
    [ -d "${PROJECT_ROOT}/.github/workflows" ]
}

test_documentation() {
    [ -f "${PROJECT_ROOT}/.github/README.md" ] && \
    [ -f "${PROJECT_ROOT}/QUICKSTART-UBUNTU.md" ]
}

# =============================================================================
# YAML SYNTAX VALIDATION
# =============================================================================

test_yaml_syntax() {
    # Test YAML syntax if python is available
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import yaml
import sys
try:
    with open('${PROJECT_ROOT}/.github/workflows/build-iso.yml', 'r') as f:
        yaml.safe_load(f)
    sys.exit(0)
except Exception as e:
    print(f'YAML syntax error: {e}')
    sys.exit(1)
        " 2>/dev/null
    else
        # Fallback: basic YAML structure check
        grep -q "name:" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
        grep -q "on:" "${PROJECT_ROOT}/.github/workflows/build-iso.yml" && \
        grep -q "jobs:" "${PROJECT_ROOT}/.github/workflows/build-iso.yml"
    fi
}

# =============================================================================
# RUN ALL TESTS
# =============================================================================

main() {
    log "GitHub Actions Workflow Verification Tests"
    log "==========================================="

    # Workflow file tests
    run_test "Workflow file exists" "test_workflow_exists"
    run_test "Uses Ubuntu 24.04 runner" "test_workflow_ubuntu_runner"
    run_test "Proper trigger configuration" "test_workflow_triggers"
    run_test "Uses make commands" "test_workflow_make_commands"
    run_test "Artifact upload configuration" "test_workflow_artifacts"
    run_test "Build type options" "test_workflow_build_types"
    run_test "Build timeout configured" "test_workflow_timeout"
    run_test "Disk space cleanup" "test_workflow_disk_cleanup"
    run_test "Caching configuration" "test_workflow_caching"
    run_test "Release automation" "test_workflow_releases"

    # Compatibility tests
    run_test "Makefile targets present" "test_makefile_targets"
    run_test "Makefile Ubuntu configuration" "test_makefile_ubuntu"

    # Structure tests
    run_test "GitHub directory structure" "test_github_directory"
    run_test "Documentation present" "test_documentation"

    # Syntax validation
    run_test "YAML syntax validation" "test_yaml_syntax"

    # Summary
    log "==========================================="
    log "Tests Run: $TESTS_RUN"
    log "Passed: $TESTS_PASSED"
    log "Failed: $TESTS_FAILED"

    if [ $TESTS_FAILED -eq 0 ]; then
        log "🎉 All tests passed! GitHub Actions workflow is ready."
        log ""
        log "Next steps:"
        log "1. Commit and push to main branch"
        log "2. Check GitHub Actions tab for build progress"
        log "3. Download ISO from GitHub releases"
        exit 0
    else
        error "❌ $TESTS_FAILED tests failed. Please fix issues before pushing."
        exit 1
    fi
}

main "$@"