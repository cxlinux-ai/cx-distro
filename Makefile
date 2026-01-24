<<<<<<< HEAD
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
=======
# Makefile —— Cortex Linux build orchestrator
SHELL         := /usr/bin/env bash
<<<<<<< HEAD
.DEFAULT_GOAL := current
>>>>>>> 4c950da (v2)
=======
.DEFAULT_GOAL := build
>>>>>>> 9657e72 (Refactor build process and configuration management for Cortex Linux)

SRC_DIR       := src
CONFIG_DIR    := config

# Architecture detection (defaults to amd64)
ARCH ?= $(shell dpkg --print-architecture 2>/dev/null || echo amd64)

# Check if apt-cacher-ng is running (only use if available)
# First check if service is active, then test port connectivity
# Falls back to empty string if not available (no caching)
APT_CACHER_NG_URL := $(shell (systemctl is-active --quiet apt-cacher-ng 2>/dev/null || pgrep -x apt-cacher-ng >/dev/null 2>&1) && (timeout 1 bash -c 'exec 3<>/dev/tcp/localhost/3142' 2>/dev/null && echo "http://localhost:3142") || echo "")

# Common dependencies
COMMON_DEPS := \
  binutils \
  debootstrap \
  squashfs-tools \
  xorriso \
  grub2-common \
  mtools \
  dosfstools

<<<<<<< HEAD
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
	@echo "Package Targets:"
	@echo "  make packages         Build all .deb packages"
	@echo "  make build-package PKG=name  Build specific package"
	@echo "                        Available: cortex-branding cortex-core cortex-full cortex-secops"
	@echo ""
	@echo "Branding Targets:"
	@echo "  make branding-package Build cortex-branding .deb package"
	@echo "  (To install: sudo apt install ./output/cortex-branding_*.deb)"
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
	@$(BUILD_SCRIPT) clean

clean-all:
	@$(BUILD_SCRIPT) clean-all

clean-hooks:
	@$(BUILD_SCRIPT) clean-hooks

sync-config:
	@$(BUILD_SCRIPT) sync

# =============================================================================
# Test
# =============================================================================

test:
	@$(BUILD_SCRIPT) test

# =============================================================================
# Packages
# =============================================================================

# Build all packages
packages:
	@$(BUILD_SCRIPT) build-package all

# Build specific package (usage: make build-package PKG=cortex-branding)
build-package:
ifdef PKG
	@$(BUILD_SCRIPT) build-package $(PKG)
=======
# Architecture-specific GRUB packages
ifeq ($(ARCH),amd64)
  DEPS := $(COMMON_DEPS) grub-pc-bin grub-efi-amd64-bin
else ifeq ($(ARCH),arm64)
  DEPS := $(COMMON_DEPS) grub-efi-arm64-bin
>>>>>>> 4c950da (v2)
else
  DEPS := $(COMMON_DEPS)
endif

.PHONY: build clean bootstrap help

help:
	@echo "Usage:"
	@echo "  make          (or make build)     Build release for detected architecture"
	@echo "  make clean                        Remove build artifacts"
	@echo "  make bootstrap                    Validate environment and deps"

bootstrap:
	@if [ "$$(id -u)" -eq 0 ]; then \
	  echo "Error: Do not run as root"; \
	  exit 1; \
	fi
	@if ! lsb_release -i | grep -qE "(Ubuntu|Debian|Tuxedo|Cortex)"; then \
	  echo "Error: Unsupported OS — only Ubuntu, Debian, Tuxedo or Cortex Linux allowed"; \
	  exit 1; \
	fi
	@echo "[MAKE] Architecture: $(ARCH)"
	@echo "[MAKE] Installing build dependencies..."
	@ARCH=$(ARCH) sudo bash scripts/install-deps.sh

build: bootstrap
	@echo "[MAKE] Building release for $(ARCH)..."
	@if [ -n "$(APT_CACHER_NG_URL)" ]; then \
		echo "[MAKE] Using apt-cacher-ng: $(APT_CACHER_NG_URL)"; \
	else \
		echo "[MAKE] apt-cacher-ng not available, using direct connection"; \
	fi
ifeq ($(ARCH),amd64)
	@cd $(SRC_DIR) && ARCH=$(ARCH) APT_CACHER_NG_URL="$(APT_CACHER_NG_URL)" ./build.sh -c ../$(CONFIG_DIR)/release-amd64.json
else ifeq ($(ARCH),arm64)
	@cd $(SRC_DIR) && ARCH=$(ARCH) APT_CACHER_NG_URL="$(APT_CACHER_NG_URL)" ./build.sh -c ../$(CONFIG_DIR)/release-arm64.json
else
	@echo "[ERROR] Unsupported architecture: $(ARCH). Only amd64 and arm64 are supported."
	@exit 1
endif

clean:
	@echo "[MAKE] Cleaning build artifacts..."
	@./clean_all.sh
	@echo "[MAKE] Clean complete."
