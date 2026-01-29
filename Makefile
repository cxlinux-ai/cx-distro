# CX Linux Distribution Build System
# Copyright 2025 AI Venture Holdings LLC
# SPDX-License-Identifier: Apache-2.0

# Makefile —— CX Linux build orchestrator
SHELL         := /usr/bin/env bash
.DEFAULT_GOAL := build

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

# Architecture-specific GRUB packages
ifeq ($(ARCH),amd64)
  DEPS := $(COMMON_DEPS) grub-pc-bin grub-efi-amd64-bin
else ifeq ($(ARCH),arm64)
  DEPS := $(COMMON_DEPS) grub-efi-arm64-bin
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