# Cortex Linux Branding Asset Generator
#
# Generates branding assets from source images.
# This Makefile is part of the cortex-branding package.
#
# Run: make        (builds only changed assets)
# Run: make clean  (removes generated assets)
# Run: make all    (force rebuild everything)
#

# Source logo (in this directory)
LOGO_PRIMARY := source/cx-logo-primary.png
LOGO_FALLBACK := source/cx-logo-light.png source/cx-logo-transparent.png

# Colors
DARK_BG := \#0F0F23
DARKER_BG := \#0A0A18
PRIMARY_PURPLE := \#6B21A8
ELECTRIC_CYAN := \#06B6D4
SURFACE := \#1E1E3F
TEXT_LIGHT := \#E2E8F0

# Output directories (relative to this Makefile)
PLYMOUTH_DIR := usr/share/plymouth/themes/cortex
GRUB_DIR := boot/grub/themes/cortex
WALLPAPER_DIR := usr/share/backgrounds/cortex
LOGO_DIR := usr/share/cortex/logos

# All targets
PLYMOUTH_ASSETS := $(PLYMOUTH_DIR)/logo.png $(PLYMOUTH_DIR)/entry.png $(PLYMOUTH_DIR)/bullet.png \
                   $(PLYMOUTH_DIR)/dot-on.png $(PLYMOUTH_DIR)/dot-off.png

GRUB_ASSETS := $(GRUB_DIR)/background.png $(GRUB_DIR)/icons/cortex.png $(GRUB_DIR)/icons/linux.png \
               $(GRUB_DIR)/icons/recovery.png $(GRUB_DIR)/select_c.png $(GRUB_DIR)/select_w.png \
               $(GRUB_DIR)/select_e.png $(GRUB_DIR)/scrollbar_thumb.png $(GRUB_DIR)/scrollbar_frame.png

WALLPAPER_ASSETS := $(WALLPAPER_DIR)/minimal-dark.png $(WALLPAPER_DIR)/circuit-board.png

LOGO_ASSETS := $(LOGO_DIR)/cortex-icon-128.png $(LOGO_DIR)/favicon-32.png

ALL_ASSETS := $(PLYMOUTH_ASSETS) $(GRUB_ASSETS) $(WALLPAPER_ASSETS) $(LOGO_ASSETS)

# Default target
.PHONY: default
default: $(ALL_ASSETS)
	@echo ""
	@echo "✓ Branding assets generated"
	@echo ""

# Force rebuild all
.PHONY: all
all: clean default

# Clean generated assets
.PHONY: clean
clean:
	@echo "Cleaning generated assets..."
	rm -f $(PLYMOUTH_DIR)/*.png
	rm -f $(GRUB_DIR)/*.png $(GRUB_DIR)/icons/*.png
	rm -f $(WALLPAPER_DIR)/*.png
	rm -f $(LOGO_DIR)/*.png
	@echo "✓ Clean complete"

# Create directories
$(PLYMOUTH_DIR) $(GRUB_DIR)/icons $(WALLPAPER_DIR) $(LOGO_DIR):
	mkdir -p $@

# Helper function for logo extraction
define extract_logo
	magick $(LOGO_PRIMARY) \
		-gravity center -crop 800x800+0+0 +repage \
		-resize $(1)x$(1) \
		-background none \
		-define png:color-type=6 \
		$(2)
endef

# =============================================================================
# Plymouth Assets
# =============================================================================

$(PLYMOUTH_DIR)/logo.png: $(LOGO_PRIMARY) | $(PLYMOUTH_DIR)
	@echo "  Plymouth: logo.png"
	@$(call extract_logo,300,$@)

$(PLYMOUTH_DIR)/entry.png: | $(PLYMOUTH_DIR)
	@echo "  Plymouth: entry.png"
	@magick -size 300x40 xc:transparent \
		-fill "$(DARK_BG)" \
		-stroke "$(PRIMARY_PURPLE)" -strokewidth 2 \
		-draw "roundrectangle 2,2 297,37 8,8" \
		$@

$(PLYMOUTH_DIR)/bullet.png: | $(PLYMOUTH_DIR)
	@echo "  Plymouth: bullet.png"
	@magick -size 15x15 xc:transparent \
		-fill "$(ELECTRIC_CYAN)" \
		-draw "circle 7,7 7,2" \
		$@

$(PLYMOUTH_DIR)/dot-on.png: | $(PLYMOUTH_DIR)
	@echo "  Plymouth: dot-on.png"
	@magick -size 12x12 xc:transparent -fill white \
		-draw "circle 6,6 6,1" \
		-define png:color-type=6 \
		$@

$(PLYMOUTH_DIR)/dot-off.png: | $(PLYMOUTH_DIR)
	@echo "  Plymouth: dot-off.png"
	@magick -size 12x12 xc:transparent -fill "rgb(80,80,80)" \
		-draw "circle 6,6 6,1" \
		-define png:color-type=6 \
		$@

# =============================================================================
# GRUB Assets
# =============================================================================

$(GRUB_DIR)/background.png: | $(GRUB_DIR)
	@echo "  GRUB: background.png"
	@magick -size 1920x1080 \
		"gradient:$(DARK_BG)-$(DARKER_BG)" \
		-rotate 180 \
		\( -size 1920x1080 xc:transparent \
		   -fill "rgba(107,33,168,0.03)" \
		   -draw "line 0,200 1920,200" \
		   -draw "line 0,400 1920,400" \
		   -draw "line 0,600 1920,600" \
		   -draw "line 0,800 1920,800" \
		   -draw "line 400,0 400,1080" \
		   -draw "line 800,0 800,1080" \
		   -draw "line 1200,0 1200,1080" \
		   -draw "line 1600,0 1600,1080" \
		\) -composite \
		$@

$(GRUB_DIR)/icons/cortex.png: $(LOGO_PRIMARY) | $(GRUB_DIR)/icons
	@echo "  GRUB: icons/cortex.png"
	@$(call extract_logo,32,$@)

$(GRUB_DIR)/icons/linux.png: | $(GRUB_DIR)/icons
	@echo "  GRUB: icons/linux.png"
	@magick -size 32x32 xc:transparent \
		-fill "$(TEXT_LIGHT)" -draw "polygon 16,4 6,28 26,28" \
		-fill "$(DARK_BG)" -draw "polygon 16,10 10,24 22,24" \
		$@

$(GRUB_DIR)/icons/recovery.png: | $(GRUB_DIR)/icons
	@echo "  GRUB: icons/recovery.png"
	@magick -size 32x32 xc:transparent \
		-fill "$(ELECTRIC_CYAN)" -stroke "$(ELECTRIC_CYAN)" -strokewidth 2 \
		-draw "arc 6,6 26,26 0,270" -draw "polygon 24,6 28,12 20,12" \
		$@

$(GRUB_DIR)/select_c.png: | $(GRUB_DIR)
	@magick -size 10x40 xc:transparent -fill "rgba(107,33,168,0.6)" -draw "rectangle 0,0 9,39" $@

$(GRUB_DIR)/select_w.png: | $(GRUB_DIR)
	@magick -size 10x40 xc:transparent -fill "rgba(107,33,168,0.6)" -draw "roundrectangle 0,0 19,39 8,8" -crop 10x40+0+0 +repage $@

$(GRUB_DIR)/select_e.png: | $(GRUB_DIR)
	@magick -size 10x40 xc:transparent -fill "rgba(107,33,168,0.6)" -draw "roundrectangle -10,0 9,39 8,8" $@

$(GRUB_DIR)/scrollbar_thumb.png: | $(GRUB_DIR)
	@magick -size 10x30 xc:transparent -fill "$(PRIMARY_PURPLE)" -draw "roundrectangle 2,2 7,27 3,3" $@

$(GRUB_DIR)/scrollbar_frame.png: | $(GRUB_DIR)
	@magick -size 10x100 xc:transparent -fill "$(SURFACE)" -draw "roundrectangle 3,3 6,96 2,2" $@

# =============================================================================
# Wallpapers
# =============================================================================

$(WALLPAPER_DIR)/minimal-dark.png: $(LOGO_PRIMARY) | $(WALLPAPER_DIR)
	@echo "  Wallpaper: minimal-dark.png"
	@magick -size 1920x1080 \
		"gradient:$(DARK_BG)-$(DARKER_BG)" \
		-rotate 180 \
		\( $(LOGO_PRIMARY) -gravity center -crop 800x800+0+0 +repage -resize 280x280 \) \
		-gravity center -composite \
		$@

$(WALLPAPER_DIR)/circuit-board.png: $(LOGO_PRIMARY) | $(WALLPAPER_DIR)
	@echo "  Wallpaper: circuit-board.png"
	@magick -size 1920x1080 \
		"gradient:$(DARK_BG)-$(DARKER_BG)" \
		-rotate 180 \
		-stroke "rgba(107,33,168,0.10)" -strokewidth 2 \
		-draw "line 100,0 100,300" -draw "line 100,300 300,300" \
		-draw "line 300,300 300,500" -draw "line 300,500 500,500" \
		-draw "line 700,0 700,200" -draw "line 700,200 900,200" \
		-draw "line 900,200 900,400" -draw "line 900,400 1100,400" \
		-draw "line 1400,0 1400,300" -draw "line 1400,300 1600,300" \
		-draw "line 1600,300 1600,500" -draw "line 1600,500 1800,500" \
		-draw "line 200,1080 200,800" -draw "line 200,800 400,800" \
		-draw "line 800,1080 800,900" -draw "line 800,900 1000,900" \
		-draw "line 1500,1080 1500,800" -draw "line 1500,800 1700,800" \
		-fill "rgba(6,182,212,0.25)" \
		-draw "circle 100,300 100,306" -draw "circle 300,500 300,306" \
		-draw "circle 500,500 500,306" -draw "circle 700,200 700,206" \
		-draw "circle 900,400 900,206" -draw "circle 1100,400 1100,206" \
		-draw "circle 1400,300 1400,206" -draw "circle 1600,500 1600,206" \
		-fill "rgba(107,33,168,0.20)" \
		-draw "circle 200,800 200,207" -draw "circle 400,800 400,206" \
		-draw "circle 800,900 800,207" -draw "circle 1000,900 1000,206" \
		-draw "circle 1500,800 1500,207" -draw "circle 1700,800 1700,206" \
		\( $(LOGO_PRIMARY) -gravity center -crop 800x800+0+0 +repage -resize 280x280 \) \
		-gravity center -composite \
		$@

# =============================================================================
# Logos
# =============================================================================

$(LOGO_DIR)/cortex-icon-128.png: $(LOGO_PRIMARY) | $(LOGO_DIR)
	@echo "  Logo: cortex-icon-128.png"
	@$(call extract_logo,128,$@)

$(LOGO_DIR)/favicon-32.png: $(LOGO_PRIMARY) | $(LOGO_DIR)
	@echo "  Logo: favicon-32.png"
	@$(call extract_logo,32,$@)

