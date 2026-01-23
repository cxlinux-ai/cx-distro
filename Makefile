# Makefile —— Cortex Linux build orchestrator
SHELL         := /usr/bin/env bash
.DEFAULT_GOAL := current

SRC_DIR       := src
CONFIG_DIR    := config

# Architecture detection (defaults to amd64)
ARCH ?= $(shell dpkg --print-architecture 2>/dev/null || echo amd64)

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

.PHONY: all fast current clean bootstrap help

help:
	@echo "Usage:"
	@echo "  make          (or make current)   Build current language"
	@echo "  make all                          Build all languages"
	@echo "  make fast                         Build fast config languages"
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
	@echo "[MAKE] Installing build dependencies..."
	@ARCH=$(ARCH) sudo bash scripts/install-deps.sh

current: bootstrap
	@echo "[MAKE] Building current language for $(ARCH)..."
	@cd $(SRC_DIR) && ARCH=$(ARCH) ./build.sh

all: bootstrap
	@echo "[MAKE] Building ALL languages (all.json)..."
	@./build_all.sh -c $(CONFIG_DIR)/all.json

fast: bootstrap
	@echo "[MAKE] Building FAST languages (fast.json)..."
	@./build_all.sh -c $(CONFIG_DIR)/fast.json

clean:
	@echo "[MAKE] Cleaning build artifacts..."
	@./clean_all.sh
	@echo "[MAKE] Clean complete."
