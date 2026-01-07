# Desktop Wallpaper Assets

Required wallpaper images for Cortex Linux desktop.

## Required Files

All wallpapers should be provided in multiple resolutions:
- 3840x2160 (4K)
- 2560x1440 (QHD)
- 1920x1080 (FHD)

| File | Description |
|------|-------------|
| `neural-dark.png` | Dark theme with neural network pattern (default) |
| `neural-light.png` | Light theme with neural network pattern |
| `gradient-purple.png` | Purple gradient with subtle texture |
| `gradient-cyan.png` | Cyan/teal gradient with subtle texture |
| `minimal-dark.png` | Solid dark with centered Cortex logo |
| `circuit-board.png` | Circuit board pattern, tech aesthetic |

## Color Palette

### Dark Theme
```
Background:     #0F0F23
Surface:        #1E1E3F
Border:         #2D2D5A
```

### Light Theme
```
Background:     #F8FAFC
Surface:        #FFFFFF
Border:         #E2E8F0
```

### Accent Colors
```
Primary Purple: #6B21A8
Light Purple:   #A855F7
Electric Cyan:  #06B6D4
Light Cyan:     #22D3EE
```

## Design Guidelines

1. **Neural Dark (Default)**
   - Base: Dark gradient (#0F0F23 → #0A0A18)
   - Overlay: Subtle neural network lines (10-15% opacity)
   - Accent: Purple and cyan node points
   - Feel: Professional, futuristic, clean

2. **Neural Light**
   - Base: Light gradient (#F8FAFC → #E2E8F0)
   - Overlay: Light gray neural network lines
   - Accent: Purple highlights
   - Feel: Clean, modern, accessible

3. **Gradient Purple**
   - Gradient from #1E1B4B (top-left) to #4C1D95 (bottom-right)
   - Subtle noise texture overlay (5%)
   - Optional: Small Cortex logo bottom-right

4. **Gradient Cyan**
   - Gradient from #042F2E (top) to #0E7490 (bottom)
   - Subtle mesh texture overlay
   - Tech/AI aesthetic

5. **Minimal Dark**
   - Solid #0F0F23 background
   - Centered Cortex logo (15% opacity)
   - Ultra-clean, distraction-free

6. **Circuit Board**
   - Dark base with circuit trace patterns
   - Glowing nodes at intersections
   - Cyberpunk/tech aesthetic

## Installation Path

```
/usr/share/backgrounds/cortex/
├── neural-dark.png
├── neural-light.png
├── gradient-purple.png
├── gradient-cyan.png
├── minimal-dark.png
└── circuit-board.png

/usr/share/gnome-background-properties/
└── cortex-wallpapers.xml
```
