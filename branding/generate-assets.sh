#!/bin/bash
#
# Cortex Linux Branding Asset Generator
#
# Generates placeholder image assets for branding using ImageMagick.
# These can be replaced with professional designs later.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

echo "Generating Cortex Linux branding assets..."

# ============================================================================
# Plymouth Assets
# ============================================================================
echo "Creating Plymouth assets..."
PLYMOUTH_DIR="${SCRIPT_DIR}/plymouth/cortex"
mkdir -p "${PLYMOUTH_DIR}"

# Logo - Stylized brain/neural network icon (200x200)
magick -size 200x200 xc:transparent \
    -fill "${DARK_PURPLE}" -draw "circle 100,100 100,30" \
    -fill "${PRIMARY_PURPLE}" -draw "circle 100,100 100,40" \
    -fill "transparent" -stroke "${LIGHT_PURPLE}" -strokewidth 3 \
    -draw "circle 100,100 100,60" \
    -fill "transparent" -stroke "${ELECTRIC_CYAN}" -strokewidth 2 \
    -draw "line 60,60 80,80" \
    -draw "line 140,60 120,80" \
    -draw "line 60,140 80,120" \
    -draw "line 140,140 120,120" \
    -draw "line 100,40 100,70" \
    -draw "line 100,130 100,160" \
    -draw "line 40,100 70,100" \
    -draw "line 130,100 160,100" \
    -fill "${ELECTRIC_CYAN}" \
    -draw "circle 100,70 100,75" \
    -draw "circle 100,130 100,135" \
    -draw "circle 70,100 70,105" \
    -draw "circle 130,100 130,135" \
    -draw "circle 80,80 80,84" \
    -draw "circle 120,80 120,84" \
    -draw "circle 80,120 80,124" \
    -draw "circle 120,120 120,124" \
    "${PLYMOUTH_DIR}/logo.png"

# Wordmark - "CORTEX LINUX" text (300x50)
magick -size 300x50 xc:transparent \
    -font "Helvetica-Bold" -pointsize 28 \
    -fill "${TEXT_LIGHT}" \
    -gravity center -annotate 0 "CORTEX LINUX" \
    "${PLYMOUTH_DIR}/wordmark.png"

# Progress box - Container for progress bar (400x20)
magick -size 400x20 xc:transparent \
    -fill "${SURFACE}" \
    -stroke "${BORDER}" -strokewidth 1 \
    -draw "roundrectangle 0,0 399,19 10,10" \
    "${PLYMOUTH_DIR}/progress-box.png"

# Progress bar - Gradient fill (390x10)
magick -size 390x10 \
    -define gradient:direction=east \
    "gradient:${PRIMARY_PURPLE}-${ELECTRIC_CYAN}" \
    -alpha set -channel A -evaluate set 100% \
    "${PLYMOUTH_DIR}/progress-bar.png"

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

echo "  Plymouth assets created."

# ============================================================================
# GRUB Assets
# ============================================================================
echo "Creating GRUB assets..."
GRUB_DIR="${SCRIPT_DIR}/grub/cortex"
mkdir -p "${GRUB_DIR}/icons"

# Background (1920x1080) - Dark gradient with subtle pattern
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

# Selection bar components (9-slice)
# Center (tileable)
magick -size 10x40 xc:transparent \
    -fill "rgba(107,33,168,0.6)" \
    -draw "rectangle 0,0 9,39" \
    "${GRUB_DIR}/select_c.png"

# West cap
magick -size 10x40 xc:transparent \
    -fill "rgba(107,33,168,0.6)" \
    -draw "roundrectangle 0,0 19,39 8,8" \
    -crop 10x40+0+0 +repage \
    "${GRUB_DIR}/select_w.png"

# East cap
magick -size 10x40 xc:transparent \
    -fill "rgba(107,33,168,0.6)" \
    -draw "roundrectangle -10,0 9,39 8,8" \
    "${GRUB_DIR}/select_e.png"

# Corners and edges (simplified)
magick -size 10x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_nw.png"
magick -size 10x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_ne.png"
magick -size 10x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_sw.png"
magick -size 10x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_se.png"
magick -size 40x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_n.png"
magick -size 40x10 xc:"rgba(107,33,168,0.6)" "${GRUB_DIR}/select_s.png"

# Terminal box (for GRUB command line)
magick -size 10x10 xc:"rgba(15,15,35,0.9)" "${GRUB_DIR}/terminal_box_c.png"
magick -size 10x10 xc:"rgba(15,15,35,0.9)" "${GRUB_DIR}/terminal_box_nw.png"
magick -size 10x10 xc:"rgba(15,15,35,0.9)" "${GRUB_DIR}/terminal_box_n.png"
magick -size 10x10 xc:"rgba(15,15,35,0.9)" "${GRUB_DIR}/terminal_box_ne.png"
magick -size 10x10 xc:"rgba(15,15,35,0.9)" "${GRUB_DIR}/terminal_box_w.png"
magick -size 10x10 xc:"rgba(15,15,35,0.9)" "${GRUB_DIR}/terminal_box_e.png"
magick -size 10x10 xc:"rgba(15,15,35,0.9)" "${GRUB_DIR}/terminal_box_sw.png"
magick -size 10x10 xc:"rgba(15,15,35,0.9)" "${GRUB_DIR}/terminal_box_s.png"
magick -size 10x10 xc:"rgba(15,15,35,0.9)" "${GRUB_DIR}/terminal_box_se.png"

# Scrollbar
magick -size 10x30 xc:transparent \
    -fill "${PRIMARY_PURPLE}" \
    -draw "roundrectangle 2,2 7,27 3,3" \
    "${GRUB_DIR}/scrollbar_thumb.png"

magick -size 10x100 xc:transparent \
    -fill "${SURFACE}" \
    -draw "roundrectangle 3,3 6,96 2,2" \
    "${GRUB_DIR}/scrollbar_frame.png"

# Boot menu icons (32x32)
# Cortex icon
magick -size 32x32 xc:transparent \
    -fill "${PRIMARY_PURPLE}" -draw "circle 16,16 16,4" \
    -fill "${ELECTRIC_CYAN}" -draw "circle 16,16 16,8" \
    -fill "${DARK_BG}" -draw "circle 16,16 16,12" \
    -fill "${LIGHT_PURPLE}" -draw "circle 16,16 16,14" \
    "${GRUB_DIR}/icons/cortex.png"

# Linux icon
magick -size 32x32 xc:transparent \
    -fill "${TEXT_LIGHT}" \
    -draw "polygon 16,4 6,28 26,28" \
    -fill "${DARK_BG}" \
    -draw "polygon 16,10 10,24 22,24" \
    "${GRUB_DIR}/icons/linux.png"

# Recovery icon
magick -size 32x32 xc:transparent \
    -fill "${ELECTRIC_CYAN}" \
    -stroke "${ELECTRIC_CYAN}" -strokewidth 2 \
    -draw "arc 6,6 26,26 0,270" \
    -draw "polygon 24,6 28,12 20,12" \
    "${GRUB_DIR}/icons/recovery.png"

echo "  GRUB assets created."

# ============================================================================
# Wallpapers
# ============================================================================
echo "Creating wallpaper assets..."
WALLPAPER_DIR="${SCRIPT_DIR}/wallpapers/images"
mkdir -p "${WALLPAPER_DIR}"

# Neural Dark (default) - 1920x1080
echo "  Creating neural-dark.png..."
magick -size 1920x1080 "gradient:${DARK_BG}-${DARKER_BG}" -rotate 135 \
    -fill "rgba(107,33,168,0.04)" \
    -draw "line 0,200 1920,200" -draw "line 0,400 1920,400" \
    -draw "line 0,600 1920,600" -draw "line 0,800 1920,800" \
    -draw "line 400,0 400,1080" -draw "line 800,0 800,1080" \
    -draw "line 1200,0 1200,1080" -draw "line 1600,0 1600,1080" \
    -fill "rgba(6,182,212,0.12)" \
    -draw "circle 300,200 300,206" -draw "circle 600,400 600,406" \
    -draw "circle 900,300 900,305" -draw "circle 1200,500 1200,507" \
    -draw "circle 1500,350 1500,356" -draw "circle 400,700 400,705" \
    -draw "circle 800,800 800,806" -draw "circle 1100,650 1100,656" \
    -fill "rgba(107,33,168,0.10)" \
    -draw "circle 200,400 200,206" -draw "circle 500,600 500,607" \
    -draw "circle 1000,450 1000,456" -draw "circle 1600,600 1600,607" \
    -stroke "rgba(107,33,168,0.05)" -strokewidth 1 \
    -draw "line 300,200 600,400" -draw "line 600,400 900,300" \
    -draw "line 900,300 1200,500" -draw "line 400,700 800,800" \
    -stroke "rgba(6,182,212,0.04)" \
    -draw "line 200,400 500,600" -draw "line 1000,450 1300,300" \
    "${WALLPAPER_DIR}/neural-dark.png"

# Neural Light - 1920x1080
echo "  Creating neural-light.png..."
magick -size 1920x1080 "gradient:#F8FAFC-#E2E8F0" -rotate 135 \
    -fill "rgba(107,33,168,0.06)" \
    -draw "line 0,200 1920,200" -draw "line 0,400 1920,400" \
    -draw "line 0,600 1920,600" -draw "line 0,800 1920,800" \
    -draw "line 400,0 400,1080" -draw "line 800,0 800,1080" \
    -draw "line 1200,0 1200,1080" -draw "line 1600,0 1600,1080" \
    -fill "rgba(107,33,168,0.12)" \
    -draw "circle 400,300 400,308" -draw "circle 800,500 800,508" \
    -draw "circle 1200,400 1200,407" -draw "circle 600,700 600,707" \
    -draw "circle 1000,800 1000,808" \
    -stroke "rgba(107,33,168,0.06)" -strokewidth 1 \
    -draw "line 400,300 800,500" -draw "line 800,500 1200,400" \
    -draw "line 600,700 1000,800" \
    "${WALLPAPER_DIR}/neural-light.png"

# Gradient Purple - 1920x1080
echo "  Creating gradient-purple.png..."
magick -size 1920x1080 "gradient:#1E1B4B-#4C1D95" -rotate 135 \
    "${WALLPAPER_DIR}/gradient-purple.png"

# Gradient Cyan - 1920x1080
echo "  Creating gradient-cyan.png..."
magick -size 1920x1080 "gradient:#042F2E-#0E7490" -rotate 180 \
    "${WALLPAPER_DIR}/gradient-cyan.png"

# Minimal Dark - 1920x1080
echo "  Creating minimal-dark.png..."
magick -size 1920x1080 xc:"${DARK_BG}" \
    -fill "rgba(107,33,168,0.08)" -draw "circle 960,540 960,440" \
    -fill "rgba(6,182,212,0.06)" -draw "circle 960,540 960,480" \
    "${WALLPAPER_DIR}/minimal-dark.png"

# Circuit Board - 1920x1080
echo "  Creating circuit-board.png..."
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

echo "  Wallpaper assets created."

# ============================================================================
# Logos
# ============================================================================
echo "Creating logo assets..."
LOGO_DIR="${SCRIPT_DIR}/logos"
mkdir -p "${LOGO_DIR}"

# Full logo with text (400x100)
magick -size 400x100 xc:transparent \
    \( -size 80x80 xc:transparent \
       -fill "${PRIMARY_PURPLE}" -draw "circle 40,40 40,10" \
       -fill "${ELECTRIC_CYAN}" -draw "circle 40,40 40,20" \
       -fill "${DARK_BG}" -draw "circle 40,40 40,28" \
       -fill "${LIGHT_PURPLE}" -draw "circle 40,40 40,32" \
    \) -geometry +10+10 -composite \
    -font "Helvetica-Bold" -pointsize 36 \
    -fill "${TEXT_LIGHT}" \
    -draw "text 100,60 'CORTEX'" \
    -font "Helvetica" -pointsize 36 \
    -fill "${TEXT_MUTED}" \
    -draw "text 245,60 'LINUX'" \
    "${LOGO_DIR}/cortex-logo-full-dark.png"

# Full logo light version
magick -size 400x100 xc:transparent \
    \( -size 80x80 xc:transparent \
       -fill "${PRIMARY_PURPLE}" -draw "circle 40,40 40,10" \
       -fill "${ELECTRIC_CYAN}" -draw "circle 40,40 40,20" \
       -fill "white" -draw "circle 40,40 40,28" \
       -fill "${LIGHT_PURPLE}" -draw "circle 40,40 40,32" \
    \) -geometry +10+10 -composite \
    -font "Helvetica-Bold" -pointsize 36 \
    -fill "#1E1B4B" \
    -draw "text 100,60 'CORTEX'" \
    -font "Helvetica" -pointsize 36 \
    -fill "#64748B" \
    -draw "text 245,60 'LINUX'" \
    "${LOGO_DIR}/cortex-logo-full-light.png"

# Icon only (128x128)
magick -size 128x128 xc:transparent \
    -fill "${DARK_PURPLE}" -draw "circle 64,64 64,14" \
    -fill "${PRIMARY_PURPLE}" -draw "circle 64,64 64,24" \
    -fill "transparent" -stroke "${LIGHT_PURPLE}" -strokewidth 4 \
    -draw "circle 64,64 64,40" \
    -fill "transparent" -stroke "${ELECTRIC_CYAN}" -strokewidth 2 \
    -draw "line 34,34 50,50" \
    -draw "line 94,34 78,50" \
    -draw "line 34,94 50,78" \
    -draw "line 94,94 78,78" \
    -draw "line 64,20 64,44" \
    -draw "line 64,84 64,108" \
    -draw "line 20,64 44,64" \
    -draw "line 84,64 108,64" \
    -fill "${ELECTRIC_CYAN}" \
    -draw "circle 64,44 64,48" \
    -draw "circle 64,84 64,88" \
    -draw "circle 44,64 44,68" \
    -draw "circle 84,64 84,88" \
    "${LOGO_DIR}/cortex-icon-128.png"

# Favicon (32x32)
magick -size 32x32 xc:transparent \
    -fill "${PRIMARY_PURPLE}" -draw "circle 16,16 16,4" \
    -fill "${ELECTRIC_CYAN}" -draw "circle 16,16 16,8" \
    -fill "${DARK_BG}" -draw "circle 16,16 16,11" \
    -fill "${LIGHT_PURPLE}" -draw "circle 16,16 16,13" \
    "${LOGO_DIR}/favicon-32.png"

# SVG logo (text-based for scalability)
cat > "${LOGO_DIR}/cortex-logo.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 100">
  <defs>
    <linearGradient id="iconGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#6B21A8"/>
      <stop offset="100%" style="stop-color:#06B6D4"/>
    </linearGradient>
  </defs>
  <!-- Icon -->
  <circle cx="50" cy="50" r="35" fill="#4C1D95"/>
  <circle cx="50" cy="50" r="28" fill="url(#iconGrad)"/>
  <circle cx="50" cy="50" r="18" fill="#0F0F23"/>
  <circle cx="50" cy="50" r="12" fill="#A855F7"/>
  <!-- Text -->
  <text x="100" y="62" font-family="Helvetica, Arial, sans-serif" font-weight="bold" font-size="36" fill="#E2E8F0">CORTEX</text>
  <text x="245" y="62" font-family="Helvetica, Arial, sans-serif" font-size="36" fill="#94A3B8">LINUX</text>
</svg>
SVGEOF

echo "  Logo assets created."

# ============================================================================
# GDM Assets
# ============================================================================
echo "Creating GDM assets..."
GDM_DIR="${SCRIPT_DIR}/gdm"
mkdir -p "${GDM_DIR}"

# Login background (same as neural-dark but optimized)
cp "${WALLPAPER_DIR}/neural-dark.png" "${GDM_DIR}/cortex-login-bg.png"

# Copy SVG logo for GDM
cp "${LOGO_DIR}/cortex-logo.svg" "${GDM_DIR}/cortex-logo.svg"

echo "  GDM assets created."

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=============================================="
echo "  Asset generation complete!"
echo "=============================================="
echo ""
echo "Generated assets:"
find "${SCRIPT_DIR}" -name "*.png" -o -name "*.svg" | wc -l | xargs echo "  Total images:"
echo ""
echo "Locations:"
echo "  Plymouth: ${PLYMOUTH_DIR}"
echo "  GRUB:     ${GRUB_DIR}"
echo "  Wallpapers: ${WALLPAPER_DIR}"
echo "  Logos:    ${LOGO_DIR}"
echo "  GDM:      ${GDM_DIR}"
echo ""
