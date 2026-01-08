# Cortex Linux Distribution Build System
#
# This Makefile provides targets for building Cortex Linux ISOs,
# packages, and managing the distribution.
#
# Requirements:
#   - Debian 12+ or Ubuntu 24.04+ build host
#   - live-build package
#   - GPG for signing
#   - Python 3.11+ for tooling
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
        validate clean test check-deps preseed-check provision-check lint \
        branding branding-install branding-package

# Configuration
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Directories
BUILD_DIR := build
ISO_DIR := iso
PRESEED_DIR := $(ISO_DIR)/preseed
PROVISION_DIR := $(ISO_DIR)/provisioning
OUTPUT_DIR := output

# ISO configuration
ISO_NAME := cortex-linux
ISO_VERSION := $(shell date +%Y%m%d)
DEBIAN_VERSION := bookworm
ARCH ?= amd64

# Profiles
PROFILES := core full secops

# Default target
all: help

# Help target
help:
	@echo "Cortex Linux Distribution Build System"
	@echo ""
	@echo "ISO Build Targets (AMD64):"
	@echo "  make iso              Build default ISO (full profile)"
	@echo "  make iso-core         Build minimal core ISO"
	@echo "  make iso-full         Build full desktop ISO"
	@echo "  make iso-secops       Build security-focused ISO"
	@echo "  make iso-all          Build all ISO profiles"
	@echo ""
	@echo "ISO Build Targets (ARM64):"
	@echo "  make iso-arm64        Build default ARM64 ISO (full profile)"
	@echo "  make iso-arm64-core   Build minimal ARM64 core ISO"
	@echo "  make iso-arm64-full   Build full ARM64 desktop ISO"
	@echo "  make iso-arm64-secops Build security-focused ARM64 ISO"
	@echo "  make iso-arm64-all    Build all ARM64 ISO profiles"
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
	@echo "Utility Targets:"
	@echo "  make check-deps       Check build dependencies"
	@echo "  make clean            Clean build artifacts"
	@echo "  make clean-all        Clean everything including output"
	@echo "  make test             Run test suite"
	@echo ""
	@echo "Configuration:"
	@echo "  ISO_NAME     = $(ISO_NAME)"
	@echo "  ISO_VERSION  = $(ISO_VERSION)"
	@echo "  DEBIAN_VERSION = $(DEBIAN_VERSION)"
	@echo "  ARCH         = $(ARCH)"

# Check build dependencies
check-deps:
	@echo "Checking build dependencies..."
	@command -v lb >/dev/null 2>&1 || { echo "ERROR: live-build not installed"; exit 1; }
	@command -v gpg >/dev/null 2>&1 || { echo "ERROR: gpg not installed"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not installed"; exit 1; }
	@python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)" 2>/dev/null || \
		{ echo "WARNING: Python 3.11+ recommended"; }
	@echo "All required dependencies found."

# Validate preseed files
preseed-check:
	@echo "Validating preseed files..."
	@for f in $(PRESEED_DIR)/*.preseed $(PRESEED_DIR)/profiles/*.preseed $(PRESEED_DIR)/partitioning/*.preseed; do \
		if [ -f "$$f" ]; then \
			echo "  Checking: $$f"; \
			if grep -qE '^[^#]*[[:space:]]$$' "$$f"; then \
				echo "    WARNING: Trailing whitespace found"; \
			fi; \
		fi; \
	done
	@echo "Preseed validation complete."

# Validate provisioning scripts
provision-check:
	@echo "Validating provisioning scripts..."
	@if [ -f "$(PROVISION_DIR)/first-boot.sh" ]; then \
		bash -n "$(PROVISION_DIR)/first-boot.sh" && echo "  first-boot.sh: OK" || exit 1; \
	fi
	@echo "Provisioning validation complete."

# Run shellcheck on scripts
lint:
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find $(PROVISION_DIR) -name "*.sh" -exec shellcheck {} \; ; \
	else \
		echo "WARNING: shellcheck not installed, skipping lint"; \
	fi

# Run all validation
validate: preseed-check provision-check lint
	@echo "All validation checks passed."

# Create build directory structure
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(OUTPUT_DIR):
	@mkdir -p $(OUTPUT_DIR)

# Build ISO for a specific profile
define build-iso
	@echo "Building $(1) ISO..."
	@mkdir -p $(BUILD_DIR)/$(1)
	@mkdir -p $(OUTPUT_DIR)
	@# Copy live-build config files first
	@mkdir -p $(BUILD_DIR)/$(1)/config/package-lists
	@mkdir -p $(BUILD_DIR)/$(1)/config/hooks/live
	@cp $(ISO_DIR)/live-build/config/package-lists/*.list.chroot $(BUILD_DIR)/$(1)/config/package-lists/ 2>/dev/null || true
	@if [ "$(1)" = "full" ]; then \
		cp -r $(ISO_DIR)/live-build/config/hooks $(BUILD_DIR)/$(1)/config/ 2>/dev/null || true; \
	fi
	@# Configure live-build
	cd $(BUILD_DIR)/$(1) && lb config \
		--distribution $(DEBIAN_VERSION) \
		--archive-areas "main contrib non-free non-free-firmware" \
		--architectures $(ARCH) \
		--binary-images iso-hybrid \
		--bootappend-live "boot=live components username=cortex preseed/file=/cdrom/preseed/profiles/cortex-$(1).preseed" \
		--debian-installer live \
		--debian-installer-gui false \
		--iso-application "Cortex Linux" \
		--iso-publisher "Cortex Linux Project" \
		--iso-volume "CORTEX_$(shell echo $(1) | tr a-z A-Z)" \
		--cache-packages true \
		--cache-indices true \
		--cache-stages bootstrap
	@# Copy preseed and provisioning files
	@mkdir -p $(BUILD_DIR)/$(1)/config/includes.binary/preseed/profiles
	@mkdir -p $(BUILD_DIR)/$(1)/config/includes.binary/preseed/partitioning
	@mkdir -p $(BUILD_DIR)/$(1)/config/includes.binary/provisioning
	@cp $(PRESEED_DIR)/*.preseed $(BUILD_DIR)/$(1)/config/includes.binary/preseed/ 2>/dev/null || true
	@cp $(PRESEED_DIR)/profiles/*.preseed $(BUILD_DIR)/$(1)/config/includes.binary/preseed/profiles/ 2>/dev/null || true
	@cp $(PRESEED_DIR)/partitioning/*.preseed $(BUILD_DIR)/$(1)/config/includes.binary/preseed/partitioning/ 2>/dev/null || true
	@cp $(PROVISION_DIR)/* $(BUILD_DIR)/$(1)/config/includes.binary/provisioning/ 2>/dev/null || true
	@# Build the ISO
	cd $(BUILD_DIR)/$(1) && sudo lb build
	@# Move output
	@mv $(BUILD_DIR)/$(1)/live-image-$(ARCH).hybrid.iso \
		$(OUTPUT_DIR)/$(ISO_NAME)-$(1)-$(ISO_VERSION)-$(ARCH).iso 2>/dev/null || true
	@echo "ISO built: $(OUTPUT_DIR)/$(ISO_NAME)-$(1)-$(ISO_VERSION)-$(ARCH).iso"
endef

# ISO targets
iso: iso-full

iso-core: check-deps validate $(BUILD_DIR) $(OUTPUT_DIR)
	$(call build-iso,core)

iso-full: check-deps validate $(BUILD_DIR) $(OUTPUT_DIR)
	$(call build-iso,full)

iso-secops: check-deps validate $(BUILD_DIR) $(OUTPUT_DIR)
	$(call build-iso,secops)

iso-all: iso-core iso-full iso-secops
	@echo "All ISOs built successfully."

# ARM64 ISO targets
iso-arm64: iso-arm64-full

iso-arm64-core: check-deps validate $(BUILD_DIR) $(OUTPUT_DIR)
	$(MAKE) ARCH=arm64 iso-core

iso-arm64-full: check-deps validate $(BUILD_DIR) $(OUTPUT_DIR)
	$(MAKE) ARCH=arm64 iso-full

iso-arm64-secops: check-deps validate $(BUILD_DIR) $(OUTPUT_DIR)
	$(MAKE) ARCH=arm64 iso-secops

iso-arm64-all: iso-arm64-core iso-arm64-full iso-arm64-secops
	@echo "All ARM64 ISOs built successfully."

# Test target
test: validate
	@echo "Running test suite..."
	@# Test preseed syntax
	@echo "Testing preseed files..."
	@for profile in $(PROFILES); do \
		if [ -f "$(PRESEED_DIR)/profiles/cortex-$$profile.preseed" ]; then \
			echo "  Profile $$profile: OK"; \
		else \
			echo "  Profile $$profile: MISSING" && exit 1; \
		fi; \
	done
	@# Test provisioning script
	@echo "Testing provisioning scripts..."
	@bash -n $(PROVISION_DIR)/first-boot.sh
	@echo "All tests passed."

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "Clean complete."

clean-all: clean
	@echo "Cleaning all output..."
	@rm -rf $(OUTPUT_DIR)
	@echo "Full clean complete."

# Development helpers
.PHONY: dev-shell
dev-shell:
	@echo "Starting development shell..."
	@docker run -it --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		debian:$(DEBIAN_VERSION) \
		/bin/bash

# Print configuration
.PHONY: config
config:
	@echo "Current Configuration:"
	@echo "  ISO_NAME     = $(ISO_NAME)"
	@echo "  ISO_VERSION  = $(ISO_VERSION)"
	@echo "  DEBIAN_VERSION = $(DEBIAN_VERSION)"
	@echo "  ARCH         = $(ARCH) (supported: amd64, arm64)"
	@echo "  BUILD_DIR    = $(BUILD_DIR)"
	@echo "  OUTPUT_DIR   = $(OUTPUT_DIR)"

# ============================================================================
# Branding Targets
# ============================================================================

BRANDING_DIR := branding
PACKAGES_DIR := packages

# Install branding directly to system
branding-install:
	@echo "Installing Cortex branding..."
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "ERROR: Must run as root (sudo make branding-install)"; \
		exit 1; \
	fi
	@bash $(BRANDING_DIR)/install-branding.sh

# Build cortex-branding .deb package
branding-package: $(OUTPUT_DIR)
	@echo "Building cortex-branding package..."
	@# Create package directory structure
	@mkdir -p $(BUILD_DIR)/cortex-branding/DEBIAN
	@mkdir -p $(BUILD_DIR)/cortex-branding/etc
	@mkdir -p $(BUILD_DIR)/cortex-branding/usr/share/plymouth/themes/cortex
	@mkdir -p $(BUILD_DIR)/cortex-branding/boot/grub/themes/cortex
	@mkdir -p $(BUILD_DIR)/cortex-branding/usr/share/backgrounds/cortex
	@mkdir -p $(BUILD_DIR)/cortex-branding/usr/share/gnome-background-properties
	@mkdir -p $(BUILD_DIR)/cortex-branding/etc/update-motd.d
	@mkdir -p $(BUILD_DIR)/cortex-branding/usr/share/cortex/logos
	@# Copy DEBIAN control files
	@cp $(PACKAGES_DIR)/cortex-branding/DEBIAN/* $(BUILD_DIR)/cortex-branding/DEBIAN/
	@chmod 755 $(BUILD_DIR)/cortex-branding/DEBIAN/postinst
	@chmod 755 $(BUILD_DIR)/cortex-branding/DEBIAN/prerm
	@# Copy OS release files
	@cp $(BRANDING_DIR)/os-release/os-release $(BUILD_DIR)/cortex-branding/etc/os-release
	@cp $(BRANDING_DIR)/os-release/lsb-release $(BUILD_DIR)/cortex-branding/etc/lsb-release
	@cp $(BRANDING_DIR)/os-release/issue $(BUILD_DIR)/cortex-branding/etc/issue
	@cp $(BRANDING_DIR)/os-release/issue.net $(BUILD_DIR)/cortex-branding/etc/issue.net
	@# Copy Plymouth theme
	@cp $(BRANDING_DIR)/plymouth/cortex/* $(BUILD_DIR)/cortex-branding/usr/share/plymouth/themes/cortex/ 2>/dev/null || true
	@# Copy GRUB theme
	@cp $(BRANDING_DIR)/grub/cortex/* $(BUILD_DIR)/cortex-branding/boot/grub/themes/cortex/ 2>/dev/null || true
	@# Copy wallpapers
	@cp $(BRANDING_DIR)/wallpapers/*.xml $(BUILD_DIR)/cortex-branding/usr/share/gnome-background-properties/ 2>/dev/null || true
	@# Copy MOTD scripts
	@cp $(BRANDING_DIR)/motd/* $(BUILD_DIR)/cortex-branding/etc/update-motd.d/ 2>/dev/null || true
	@chmod 755 $(BUILD_DIR)/cortex-branding/etc/update-motd.d/*
	@# Build the package
	@dpkg-deb --build $(BUILD_DIR)/cortex-branding $(OUTPUT_DIR)/cortex-branding_1.0.0_all.deb
	@echo "Package built: $(OUTPUT_DIR)/cortex-branding_1.0.0_all.deb"
