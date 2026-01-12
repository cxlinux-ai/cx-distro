# CX Linux Distribution Build System
# Copyright 2025 AI Venture Holdings LLC
# SPDX-License-Identifier: Apache-2.0
#
# This Makefile provides targets for building Cortex Linux ISOs,
# packages, and managing the distribution.
#
# Usage:
#   make help           - Show available targets
#   make iso            - Build ISO
#   make validate       - Validate preseed files
#   make clean          - Clean build artifacts

.PHONY: all help iso iso-arm64 \
        validate clean clean-all clean-hooks sync-config test check-deps install-deps \
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
	@echo "ISO Build Targets:"
	@echo "  make iso              Build Cortex Linux ISO"
	@echo "  make iso-arm64        Build ARM64 ISO"
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
	@echo "  make install-deps     Install build dependencies (requires sudo)"
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

install-deps:
	@sudo scripts/install-deps.sh

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

iso: check-deps validate
	@ARCH=$(ARCH) DEBIAN_VERSION=$(DEBIAN_VERSION) ISO_NAME=$(ISO_NAME) ISO_VERSION=$(ISO_VERSION) \
		$(BUILD_SCRIPT) build

iso-arm64:
	$(MAKE) ARCH=arm64 iso

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
	@if [ -d "$(BUILD_DIR)/chroot" ]; then \
		echo "Entering chroot..."; \
		sudo chroot "$(BUILD_DIR)/chroot" /bin/bash; \
	else \
		echo "ERROR: Chroot not found at $(BUILD_DIR)/chroot"; \
		echo "Run 'make iso' first to create it"; \
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
