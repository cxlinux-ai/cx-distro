# Plymouth Theme Assets

Required image assets for the Cortex Linux Plymouth theme.

## Required Files

| File | Dimensions | Description |
|------|------------|-------------|
| `logo.png` | 200x200 | CX monogram logo (transparent) |
| `wordmark.png` | 300x50 | "CORTEX LINUX" text (transparent) |
| `spinner-track.png` | 100x100 | Circular spinner background ring (subtle) |
| `throbber-0000.png` to `throbber-0023.png` | 100x100 | 24-frame spinner animation (gradient arc) |
| `entry.png` | 300x40 | Password entry box (dark, rounded) |
| `bullet.png` | 15x15 | Password bullet character |

## Spinner Animation

The spinner uses a 24-frame animation for smooth rotation:
- Gradient arc from purple (#6B21A8) to cyan (#06B6D4)
- Fading opacity trail for motion blur effect
- Frames are named `throbber-NNNN.png` (Plymouth standard format)

## Color Palette

```
Primary Purple:   #6B21A8 (rgb: 107, 33, 168)
Electric Cyan:    #06B6D4 (rgb: 6, 182, 212)
Dark Background:  #0F0F23 (rgb: 15, 15, 35)
Text Light:       #E2E8F0 (rgb: 226, 232, 240)
Text Muted:       #94A3B8 (rgb: 148, 163, 184)
```

## Logo Concept

The Cortex logo is a "CX" monogram in a circular badge:
- Bold, stylized "CX" letters representing "Cortex"
- Circular ring with purple-to-cyan gradient
- Circuit board traces extending horizontally
- Modern, clean, tech-forward aesthetic
- Works on dark backgrounds

## Asset Generation

All assets are generated automatically from source logos using the
`generate-assets.sh` script. The source logos are located in:

- `branding/source/cx-logo-transparent.png` - Logo with transparent background
- `branding/source/cx-logo-dark.png` - Logo on dark space-like background

To regenerate assets:
```bash
cd branding
./generate-assets.sh
```
