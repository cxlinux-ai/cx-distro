# Cortex Linux Branding Assets - Complete Replacement List

This document lists all images, logos, wallpapers, and screenshots that need to be replaced with Cortex Linux branding.

## Priority: CRITICAL (Required for MVP)

### 1. Boot & Plymouth (Boot Splash Screen)
**Location:** `src/mods/19-plymouth-patch/`
- **`logo_128.png`** (128x128px)
  - Used as: Plymouth boot splash fallback logo
  - Installed to: `/usr/share/plymouth/themes/spinner/bgrt-fallback.png`
  - Format: PNG, transparent background recommended
  
- **`cortex_text.png`** (Text logo)
  - Used as: Plymouth boot splash watermark and Ubuntu logo replacement
  - Installed to: 
    - `/usr/share/plymouth/ubuntu-logo.png`
    - `/usr/share/plymouth/themes/spinner/watermark.png`
  - Format: PNG, should work on dark backgrounds

### 2. GDM Login Screen
**Location:** `src/mods/35-dconf-patch/`
- **`cortex_text_smaller.png`** (Smaller text logo)
  - Used as: GDM (login screen) logo
  - Installed to: `/usr/share/pixmaps/cortex_text_smaller.png`
  - Format: PNG, should be visible on login screen background
  - Referenced in: `greeter.dconf-defaults.ini`

### 3. GNOME Arc Menu Extension
**Location:** `src/mods/30-gnome-extension-arcmenu-patch/`
- **`logo.svg`** (Vector logo)
  - Used as: Arc Menu button icon
  - Installed to: `/usr/share/gnome-shell/extensions/arcmenu@arcmenu.com/icons/cortex-logo.svg`
  - Format: SVG (vector), scalable
  - Referenced in: `dconf-db/03-gnome-extensions.conf`

### 4. Ubuntu Logo Text Replacement
**Location:** `src/mods/36-ubuntu-logo-text/`
- **`ubuntu-logo-text.png`** (Light theme)
  - Used as: Ubuntu logo text replacement in light theme
  - Installed to: `/usr/share/pixmaps/ubuntu-logo-text.png`
  - Format: PNG
  
- **`ubuntu-logo-text-dark.png`** (Dark theme)
  - Used as: Ubuntu logo text replacement in dark theme
  - Installed to: `/usr/share/pixmaps/ubuntu-logo-text-dark.png`
  - Format: PNG

## Priority: HIGH (Important for Branding)

### 5. GRUB Boot Menu Theme
**Location:** `packages/cortex-branding/boot/grub/themes/cortex/`
- **`background.png`** (GRUB background)
  - Used as: GRUB boot menu background
  - Format: PNG, typically 1920x1080 or similar
  
- **`icons/cortex.png`** (Boot option icon)
  - Used as: Icon for Cortex Linux boot option
  - Format: PNG
  
- **`icons/linux.png`** (Generic Linux icon)
  - Used as: Icon for generic Linux boot options
  - Format: PNG
  
- **`icons/recovery.png`** (Recovery mode icon)
  - Used as: Icon for recovery mode boot option
  - Format: PNG
  
- **`scrollbar_frame.png`** (Scrollbar frame)
  - Used as: GRUB scrollbar frame
  - Format: PNG
  
- **`scrollbar_thumb.png`** (Scrollbar thumb)
  - Used as: GRUB scrollbar thumb
  - Format: PNG
  
- **`select_c.png`** (Selection indicator center)
  - Used as: GRUB selection indicator (center)
  - Format: PNG
  
- **`select_e.png`** (Selection indicator end)
  - Used as: GRUB selection indicator (end)
  - Format: PNG
  
- **`select_w.png`** (Selection indicator west)
  - Used as: GRUB selection indicator (west)
  - Format: PNG

### 6. Plymouth Theme (Full Theme)
**Location:** `packages/cortex-branding/usr/share/plymouth/themes/cortex/`
- **`logo.png`** (Main logo)
  - Used as: Main Plymouth theme logo
  - Format: PNG
  
- **`entry.png`** (Entry point)
  - Used as: Plymouth entry point graphic
  - Format: PNG
  
- **`bullet.png`** (Bullet point)
  - Used as: Plymouth bullet point
  - Format: PNG
  
- **`dot-on.png`** (Active dot)
  - Used as: Active progress dot
  - Format: PNG
  
- **`dot-off.png`** (Inactive dot)
  - Used as: Inactive progress dot
  - Format: PNG
  
- **`animation/progress-*.png`** (240 frames)
  - Used as: Plymouth boot animation frames
  - Format: PNG, numbered progress-1.png through progress-240.png
  - Note: These are animation frames - may need to be generated or replaced with video

- **`cortex-boot.webm`** (Boot animation video)
  - Used as: Alternative boot animation (video format)
  - Format: WebM video

### 7. Desktop Wallpapers
**Location:** `src/mods/23-wallpaper-mod/`
- **`Fluent-building-light.png`** (Light wallpaper)
  - Used as: Default light theme wallpaper
  - Installed to: `/usr/share/backgrounds/Fluent-building-light.png`
  - Format: PNG, typically 1920x1080 or higher
  
- **`Fluent-building-night.png`** (Dark wallpaper)
  - Used as: Default dark theme wallpaper
  - Installed to: `/usr/share/backgrounds/Fluent-building-night.png`
  - Format: PNG, typically 1920x1080 or higher

**Location:** `packages/cortex-branding/usr/share/backgrounds/cortex/`
- **`circuit-board.png`** (Circuit board wallpaper)
  - Used as: Alternative Cortex-branded wallpaper
  - Format: PNG
  
- **`minimal-dark.png`** (Minimal dark wallpaper)
  - Used as: Alternative minimal dark wallpaper
  - Format: PNG

### 8. System Logos & Icons
**Location:** `packages/cortex-branding/usr/share/cortex/logos/`
- **`cortex-icon-128.png`** (128x128 icon)
  - Used as: System icon/logo
  - Format: PNG, 128x128px
  
- **`cortex-logo-light.svg`** (Light logo SVG)
  - Used as: Light theme logo (vector)
  - Format: SVG
  
- **`favicon-32.png`** (32x32 favicon)
  - Used as: Favicon/web icon
  - Format: PNG, 32x32px

**Location:** `packages/cortex-branding/source/`
- **`cx-logo-dark.png`** (Dark logo)
  - Used as: Source logo (dark variant)
  - Format: PNG
  
- **`cx-logo-light.png`** (Light logo)
  - Used as: Source logo (light variant)
  - Format: PNG
  
- **`cx-logo-primary.png`** (Primary logo)
  - Used as: Primary source logo
  - Format: PNG
  
- **`cx-logo-transparent.png`** (Transparent logo)
  - Used as: Source logo with transparency
  - Format: PNG
  
- **`cx-original.png`** (Original logo)
  - Used as: Original source logo
  - Format: PNG

## Priority: MEDIUM (Installer & Screenshots)

### 9. Ubiquity Installer Slideshow
**Location:** `src/mods/22-ubiquity-patch/slides/`
- **`screenshots/welcome.png`** (Welcome slide screenshot)
  - Used as: Installer welcome slide
  - Format: PNG
  
- **`screenshots/gaming.png`** (Gaming slide screenshot)
  - Used as: Installer gaming features slide
  - Format: PNG
  
- **`screenshots/sc.png`** (Screenshot)
  - Used as: Installer slide screenshot
  - Format: PNG
  
- **`screenshots/st.png`** (Screenshot)
  - Used as: Installer slide screenshot
  - Format: PNG
  
- **`screenshots/pv.png`** (Screenshot)
  - Used as: Installer slide screenshot
  - Format: PNG
  
- **`screenshots/jb.png`** (Screenshot)
  - Used as: Installer slide screenshot
  - Format: PNG

- **`link/background.png`** (Slide background)
  - Used as: Installer slide background
  - Format: PNG
  
- **`link/bullet-point.png`** (Bullet point)
  - Used as: Installer slide bullet point
  - Format: PNG
  
- **`link/arrow-back.png`** (Back arrow)
  - Used as: Installer navigation arrow (back)
  - Format: PNG
  
- **`link/arrow-next.png`** (Next arrow)
  - Used as: Installer navigation arrow (next)
  - Format: PNG

### 10. Repository Screenshot
**Location:** Root directory
- **`screenshot.png`** (Main screenshot)
  - Used as: Repository README screenshot
  - Format: PNG, typically 1920x1080 or similar
  - Displayed in: `README.md`

## Summary by Priority

### CRITICAL (Must Replace for MVP):
1. `src/mods/19-plymouth-patch/logo_128.png`
2. `src/mods/19-plymouth-patch/cortex_text.png`
3. `src/mods/35-dconf-patch/cortex_text_smaller.png`
4. `src/mods/30-gnome-extension-arcmenu-patch/logo.svg`
5. `src/mods/36-ubuntu-logo-text/ubuntu-logo-text.png`
6. `src/mods/36-ubuntu-logo-text/ubuntu-logo-text-dark.png`

### HIGH (Important for Branding):
7. GRUB theme assets (9 files)
8. Plymouth theme assets (245+ files including animation frames)
9. Desktop wallpapers (4 files)
10. System logos & icons (8 files)

### MEDIUM (Can be done later):
11. Installer slideshow screenshots (6 files)
12. Installer UI elements (4 files)
13. Repository screenshot (1 file)

## Notes

- **Animation Frames**: The Plymouth theme has 240 animation frames (`progress-1.png` through `progress-240.png`). These can be generated programmatically or replaced with a video file (`cortex-boot.webm`).

- **Vector vs Raster**: SVG files are preferred for logos that need to scale (Arc Menu icon). PNG files are used for fixed-size displays.

- **Theme Consistency**: Ensure all logos maintain visual consistency across light/dark themes and different sizes.

- **File Naming**: Some files are already renamed (e.g., `cortex_text.png` instead of `anduinos_text.png`), but the actual image content still needs to be replaced.

- **Ubiquity Installer**: Note that the build system uses Ubiquity installer (Ubuntu's installer). If migrating to Calamares, these installer assets may not be needed.

## Current Status

✅ File names updated to Cortex branding
⏳ Image content needs to be replaced with Cortex Linux assets
⏳ Plymouth animation frames need to be generated/replaced
⏳ Installer screenshots need to be created

