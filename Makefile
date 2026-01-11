# CX Linux Distribution Build System
# Copyright 2025 AI Venture Holdings LLC
# SPDX-License-Identifier: Apache-2.0
#
# This Makefile provides targets for building Cortex Linux ISOs,
# packages, and managing the distribution.
#
# Usage:
#   make help           - Show available targets
#   make iso            - Build default ISO (full profile)
#   make iso-core       - Build minimal ISO
#   make iso-secops     - Build security-focused ISO
#   make validate       - Validate preseed files
#   make clean          - Clean build artifacts

.PHONY: all help iso iso-core iso-full iso-secops iso-all \
        iso-arm64 iso-arm64-core iso-arm64-full iso-arm64-secops iso-arm64-all \
        validate clean clean-all clean-hooks sync-config test check-deps \
        preseed-check provision-check lint branding-install branding-package \
        chroot-shell config

# Configuration
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Directories
BUILD_DIR := build
OUTPUT_DIR := output

# ISO configuration
ISO_NAME := cortex-linux
ISO_VERSION := $(shell date +%Y%m%d)
DEBIAN_VERSION := bookworm
ARCH ?= amd64

# Build script
BUILD_SCRIPT := scripts/build.sh

# Default target
all: help

# =============================================================================
# Help
# =============================================================================

help:
	@echo "CX Linux Distribution Build System"
	@echo ""
	@echo "ISO Build Targets (AMD64):"
	@echo "  make iso              Build default ISO (full profile)"
	@echo "  make iso-core         Build minimal core ISO"
	@echo "  make iso-full         Build full desktop ISO"
	@echo "  make iso-secops       Build security-focused ISO"
	@echo "  make iso-all          Build all ISO profiles"
	@echo ""
	@echo "Targets:"
	@echo "  iso           Build full offline ISO (default)"
	@echo "  iso-netinst   Build minimal network installer ISO"
	@echo "  iso-offline   Build full offline ISO with package pool"
	@echo "  package       Build all meta-packages"
	@echo "  package PKG=x Build specific package (cx-core, cx-full, cx-archive-keyring)"
	@echo "  sbom          Generate Software Bill of Materials"
	@echo "  test          Run build verification tests"
	@echo "  clean         Remove build artifacts"
	@echo "  deps          Install build dependencies"
	@echo ""
	@echo "Architecture Selection:"
	@echo "  ARCH=arm64 make iso   Build ISO for specified architecture"
	@echo ""
	@echo "Validation Targets:"
	@echo "  make validate         Run all validation checks"
	@echo "  make preseed-check    Validate preseed syntax"
	@echo "  make provision-check  Validate provisioning scripts"
	@echo "  make lint             Run shellcheck on scripts"
	@echo ""
	@echo "Branding Targets:"
	@echo "  make branding-install Install branding to system (requires sudo)"
	@echo "  make branding-package Build cortex-branding .deb package"
	@echo ""
	@echo "Development Targets:"
	@echo "  make chroot-shell     Enter interactive shell in chroot filesystem"
	@echo ""
	@echo "Utility Targets:"
	@echo "  make check-deps       Check build dependencies"
	@echo "  make clean            Clean build artifacts"
	@echo "  make clean-all        Clean everything including output"
	@echo "  make test             Run test suite"
	@echo ""
	@echo "Configuration:"
	@echo "  ISO_NAME       = $(ISO_NAME)"
	@echo "  ISO_VERSION    = $(ISO_VERSION)"
	@echo "  DEBIAN_VERSION = $(DEBIAN_VERSION)"
	@echo "  ARCH           = $(ARCH)"

# =============================================================================
# Dependencies & Validation
# =============================================================================

check-deps:
	@$(BUILD_SCRIPT) check-deps

preseed-check:
	@$(BUILD_SCRIPT) validate preseed

provision-check:
	@$(BUILD_SCRIPT) validate provision

lint:
	@$(BUILD_SCRIPT) validate lint

validate:
	@$(BUILD_SCRIPT) validate all

# =============================================================================
# ISO Build Targets
# =============================================================================

iso: iso-full

iso-core: check-deps validate
	@ARCH=$(ARCH) DEBIAN_VERSION=$(DEBIAN_VERSION) ISO_NAME=$(ISO_NAME) ISO_VERSION=$(ISO_VERSION) \
		$(BUILD_SCRIPT) build core

iso-full: check-deps validate
	@ARCH=$(ARCH) DEBIAN_VERSION=$(DEBIAN_VERSION) ISO_NAME=$(ISO_NAME) ISO_VERSION=$(ISO_VERSION) \
		$(BUILD_SCRIPT) build full

iso-secops: check-deps validate
	@ARCH=$(ARCH) DEBIAN_VERSION=$(DEBIAN_VERSION) ISO_NAME=$(ISO_NAME) ISO_VERSION=$(ISO_VERSION) \
		$(BUILD_SCRIPT) build secops

iso-all: iso-core iso-full iso-secops
	@echo "All ISOs built successfully."

# ARM64 ISO targets
iso-arm64: iso-arm64-full

iso-arm64-core:
	$(MAKE) ARCH=arm64 iso-core

iso-arm64-full:
	$(MAKE) ARCH=arm64 iso-full

iso-arm64-secops:
	$(MAKE) ARCH=arm64 iso-secops

iso-arm64-all: iso-arm64-core iso-arm64-full iso-arm64-secops
	@echo "All ARM64 ISOs built successfully."

# =============================================================================
# Clean Targets
# =============================================================================

clean:
	@$(BUILD_SCRIPT) clean all

clean-all:
	@$(BUILD_SCRIPT) clean-all

clean-hooks:
	@$(BUILD_SCRIPT) clean-hooks

sync-config:
	@$(BUILD_SCRIPT) sync all

# =============================================================================
# Test
# =============================================================================

test:
	@$(BUILD_SCRIPT) test

# =============================================================================
# Branding
# =============================================================================

branding-install:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "ERROR: Must run as root (sudo make branding-install)"; \
		exit 1; \
	fi
	@bash branding/install-branding.sh

branding-package:
	@$(BUILD_SCRIPT) branding-package

# =============================================================================
# Development Helpers
# =============================================================================

# Enter interactive shell inside the chroot filesystem
chroot-shell:
	@PROFILE=$${PROFILE:-full}; \
	if [ -d "$(BUILD_DIR)/$$PROFILE/chroot" ]; then \
		echo "Entering chroot for profile '$$PROFILE'..."; \
		sudo chroot "$(BUILD_DIR)/$$PROFILE/chroot" /bin/bash; \
	else \
		echo "ERROR: Chroot for profile '$$PROFILE' not found."; \
		echo "Run 'make iso-$$PROFILE' first or specify PROFILE=<core|full|secops>"; \
		exit 1; \
	fi

# =============================================================================
# Configuration
# =============================================================================

config:
	@echo "Current Configuration:"
	@echo "  ISO_NAME       = $(ISO_NAME)"
	@echo "  ISO_VERSION    = $(ISO_VERSION)"
	@echo "  DEBIAN_VERSION = $(DEBIAN_VERSION)"
	@echo "  ARCH           = $(ARCH) (supported: amd64, arm64)"
	@echo "  BUILD_DIR      = $(BUILD_DIR)"
	@echo "  OUTPUT_DIR     = $(OUTPUT_DIR)"
