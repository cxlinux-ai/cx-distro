#!/bin/bash
#
# Cortex Linux Branding Asset Generator
#
# Generates branding assets from source logo images using ImageMagick.
# Uses the CX monogram logo from branding/source/ directory.
#
# NOTE: Assets are automatically used by live-build via symlinks.
#       No manual copying needed - just run this script and rebuild ISO.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/source"

# Source logo images
LOGO_TRANSPARENT="${SOURCE_DIR}/cx-logo-transparent.png"
LOGO_DARK="${SOURCE_DIR}/cx-logo-dark.png"
LOGO_LIGHT="${SOURCE_DIR}/cx-logo-light.png"  # Logo with gradient ring (for Plymouth)

# Verify source images exist
if [ ! -f "${LOGO_TRANSPARENT}" ]; then
    echo "ERROR: Source logo not found: ${LOGO_TRANSPARENT}"
    echo "Please add cx-logo-transparent.png to branding/source/"
    exit 1
fi

if [ ! -f "${LOGO_DARK}" ]; then
    echo "ERROR: Source logo not found: ${LOGO_DARK}"
    echo "Please add cx-logo-dark.png to branding/source/"
    exit 1
fi

if [ ! -f "${LOGO_LIGHT}" ]; then
    echo "WARNING: cx-logo-light.png not found, Plymouth will use cx-logo-transparent.png"
    LOGO_LIGHT="${LOGO_TRANSPARENT}"
fi

# Colors (Cortex brand)
PRIMARY_PURPLE="#6B21A8"
LIGHT_PURPLE="#A855F7"
DARK_PURPLE="#4C1D95"
ELECTRIC_CYAN="#06B6D4"
LIGHT_CYAN="#22D3EE"
DARK_BG="#0F0F23"
DARKER_BG="#0A0A18"
SURFACE="#1E1E3F"
BORDER="#2D2D5A"
TEXT_LIGHT="#E2E8F0"
TEXT_MUTED="#94A3B8"

echo "=============================================="
echo "  Cortex Linux Branding Asset Generator"
echo "=============================================="
echo ""
echo "Source logos: ${SOURCE_DIR}"
echo ""

# ============================================================================
# Helper function to extract and resize the circular logo
# ============================================================================
extract_logo() {
    local output_size="$1"
    local output_file="$2"
    local source_file="${3:-${LOGO_TRANSPARENT}}"
    
    # The logo is centered in the 1536x1024 image
    # Extract a square region from the center, then resize
    magick "${source_file}" \
        -gravity center \
        -crop 1024x1024+0+0 +repage \
        -resize "${output_size}x${output_size}" \
        -background none \
        "${output_file}"
}

# ============================================================================
# Plymouth Theme (minimal - just logo on black)
# ============================================================================
echo "[1/4] Plymouth theme..."
PLYMOUTH_DIR="${SCRIPT_DIR}/plymouth/cortex"
mkdir -p "${PLYMOUTH_DIR}"

# Logo - CX monogram with gradient ring (300x300)
# Uses cx-logo-light.png which has the visible gradient ring
magick "${LOGO_LIGHT}" \
    -gravity center \
    -crop 1024x1024+0+0 +repage \
    -resize 300x300 \
    -background transparent \
    "${PLYMOUTH_DIR}/logo.png"

# Entry box - Password input field (300x40)
magick -size 300x40 xc:transparent \
    -fill "${DARK_BG}" \
    -stroke "${PRIMARY_PURPLE}" -strokewidth 2 \
    -draw "roundrectangle 2,2 297,37 8,8" \
    "${PLYMOUTH_DIR}/entry.png"

# Bullet - Password character (15x15)
magick -size 15x15 xc:transparent \
    -fill "${ELECTRIC_CYAN}" \
    -draw "circle 7,7 7,2" \
    "${PLYMOUTH_DIR}/bullet.png"

echo "  ✓ logo.png, entry.png, bullet.png"

# ============================================================================
# GRUB Theme
# ============================================================================
echo "[2/4] GRUB theme..."
GRUB_DIR="${SCRIPT_DIR}/grub/cortex"
mkdir -p "${GRUB_DIR}/icons"

# Background (1920x1080)
magick -size 1920x1080 \
    "gradient:${DARK_BG}-${DARKER_BG}" \
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
    "${GRUB_DIR}/background.png"

# Selection bar (9-slice)
magick -size 10x40 xc:transparent -fill "rgba(107,33,168,0.6)" -draw "rectangle 0,0 9,39" "${GRUB_DIR}/select_c.png"
magick -size 10x40 xc:transparent -fill "rgba(107,33,168,0.6)" -draw "roundrectangle 0,0 19,39 8,8" -crop 10x40+0+0 +repage "${GRUB_DIR}/select_w.png"
magick -size 10x40 xc:transparent -fill "rgba(107,33,168,0.6)" -draw "roundrectangle -10,0 9,39 8,8" "${GRUB_DIR}/select_e.png"
magick -size 10x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_nw.png"
magick -size 10x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_ne.png"
magick -size 10x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_sw.png"
magick -size 10x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_se.png"
magick -size 40x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_n.png"
magick -size 40x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_s.png"

# Terminal box
for pos in c nw n ne w e sw s se; do
    magick -size 10x10 xc:"rgba(15,15,35,0.9)" "${GRUB_DIR}/terminal_box_${pos}.png"
done

# Scrollbar
magick -size 10x30 xc:transparent -fill "${PRIMARY_PURPLE}" -draw "roundrectangle 2,2 7,27 3,3" "${GRUB_DIR}/scrollbar_thumb.png"
magick -size 10x100 xc:transparent -fill "${SURFACE}" -draw "roundrectangle 3,3 6,96 2,2" "${GRUB_DIR}/scrollbar_frame.png"

# Boot menu icons (32x32)
extract_logo 32 "${GRUB_DIR}/icons/cortex.png"
magick -size 32x32 xc:transparent -fill "${TEXT_LIGHT}" -draw "polygon 16,4 6,28 26,28" -fill "${DARK_BG}" -draw "polygon 16,10 10,24 22,24" "${GRUB_DIR}/icons/linux.png"
magick -size 32x32 xc:transparent -fill "${ELECTRIC_CYAN}" -stroke "${ELECTRIC_CYAN}" -strokewidth 2 -draw "arc 6,6 26,26 0,270" -draw "polygon 24,6 28,12 20,12" "${GRUB_DIR}/icons/recovery.png"

echo "  ✓ background.png, selection bars, icons"

# ============================================================================
# Wallpapers
# ============================================================================
echo "[3/4] Wallpapers..."
WALLPAPER_DIR="${SCRIPT_DIR}/wallpapers/images"
mkdir -p "${WALLPAPER_DIR}"

# Circuit Board - 1920x1080
magick -size 1920x1080 xc:"${DARK_BG}" \
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
    "${WALLPAPER_DIR}/circuit-board.png"

echo "  ✓ circuit-board.png"

# ============================================================================
# Logos (for pixmaps, etc)
# ============================================================================
echo "[4/4] Logos..."
LOGO_DIR="${SCRIPT_DIR}/logos"
mkdir -p "${LOGO_DIR}"

extract_logo 128 "${LOGO_DIR}/cortex-icon-128.png"
extract_logo 32 "${LOGO_DIR}/favicon-32.png"

echo "  ✓ cortex-icon-128.png, favicon-32.png"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=============================================="
echo "  ✓ Asset generation complete!"
echo "=============================================="
echo ""
TOTAL_IMAGES=$(find "${SCRIPT_DIR}" -name "*.png" | wc -l)
echo "  Total images: ${TOTAL_IMAGES}"
echo ""
echo "  Locations (symlinked to live-build):"
echo "    branding/plymouth/cortex/  → Plymouth boot splash"
echo "    branding/grub/cortex/      → GRUB bootloader theme"
echo "    branding/wallpapers/images/→ Desktop wallpapers"
echo "    branding/logos/            → System icons/pixmaps"
echo ""
