# Plymouth Theme Assets

Required image assets for the Cortex Linux Plymouth theme.

## Required Files

| File | Dimensions | Description |
|------|------------|-------------|
| `logo.png` | 200x200 | Cortex brain/neural logo (transparent) |
| `wordmark.png` | 300x50 | "CORTEX LINUX" text (transparent) |
| `progress-box.png` | 400x20 | Progress bar container (dark, rounded) |
| `progress-bar.png` | 390x10 | Progress bar fill (gradient purple→cyan) |
| `entry.png` | 300x40 | Password entry box (dark, rounded) |
| `bullet.png` | 15x15 | Password bullet character |

## Color Palette

```
Primary Purple:   #6B21A8 (rgb: 107, 33, 168)
Electric Cyan:    #06B6D4 (rgb: 6, 182, 212)
Dark Background:  #0F0F23 (rgb: 15, 15, 35)
Text Light:       #E2E8F0 (rgb: 226, 232, 240)
Text Muted:       #94A3B8 (rgb: 148, 163, 184)
```

## Logo Concept

The Cortex logo represents an AI-powered neural network brain:
- Stylized brain outline with circuit/neural pathways
- Gradient from purple (left hemisphere) to cyan (right hemisphere)
- Modern, clean, tech-forward aesthetic
- Works on dark backgrounds

## Generation Commands

```bash
# Generate placeholder assets (requires ImageMagick)
convert -size 200x200 xc:transparent \
    -fill '#6B21A8' -draw "circle 100,100 100,20" \
    -fill '#06B6D4' -draw "circle 100,100 100,180" \
    logo.png

convert -size 400x20 xc:'#1E1E3F' -fill '#2D2D5A' \
    -draw "roundrectangle 0,0 399,19 10,10" \
    progress-box.png

convert -size 390x10 \
    -define gradient:direction=east \
    gradient:'#6B21A8'-'#06B6D4' \
    progress-bar.png
```
