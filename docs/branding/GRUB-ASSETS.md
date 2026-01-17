# GRUB Theme Assets

Required image assets for the Cortex Linux GRUB theme.

## Required Files

| File | Dimensions | Description |
|------|------------|-------------|
| `background.png` | 1920x1080 | Boot menu background |
| `select_c.png` | 10x40 | Selection bar center (tileable) |
| `select_e.png` | 10x40 | Selection bar east cap |
| `select_n.png` | 40x10 | Selection bar north cap |
| `select_ne.png` | 10x10 | Selection bar northeast corner |
| `select_nw.png` | 10x10 | Selection bar northwest corner |
| `select_s.png` | 40x10 | Selection bar south cap |
| `select_se.png` | 10x10 | Selection bar southeast corner |
| `select_sw.png` | 10x10 | Selection bar southwest corner |
| `select_w.png` | 10x40 | Selection bar west cap |
| `terminal_box_c.png` | 10x10 | Terminal background center |
| `terminal_box_*.png` | varies | Terminal box edges (8 files) |
| `scrollbar_thumb.png` | 10x30 | Scrollbar thumb |
| `scrollbar_frame.png` | 10x100 | Scrollbar track |

## Icons (Optional)

Place in `icons/` subdirectory:
- `cortex.png` - Cortex Linux entry
- `debian.png` - Debian fallback
- `linux.png` - Generic Linux
- `windows.png` - Windows (dual-boot)
- `recovery.png` - Recovery mode
- `settings.png` - UEFI settings

## Background Concept

The background should feature:
- Dark gradient (#0F0F23 to #0A0A15)
- Subtle neural network pattern overlay (10% opacity)
- Cortex logo watermark in bottom-right (15% opacity)
- Slight purple glow effect in center

## Installation

```bash
# Install theme
sudo cp -r cortex /boot/grub/themes/

# Update GRUB config
echo 'GRUB_THEME="/boot/grub/themes/cortex/theme.txt"' | sudo tee -a /etc/default/grub

# Regenerate GRUB
sudo update-grub
```
