# Desktop Wallpaper Assets

Cortex Linux desktop wallpapers with CX branding.

## Available Wallpapers

| File | Description |
|------|-------------|
| `minimal-dark.png` | Dark solid background with CX logo (default) |
| `circuit-board.png` | Circuit board pattern with CX logo |

Both wallpapers feature a subtle CX logo centered on the background.

## Color Palette

### Dark Theme
```
Background:     #0F0F23
Surface:        #1E1E3F
Border:         #2D2D5A
```

### Accent Colors
```
Primary Purple: #6B21A8
Light Purple:   #A855F7
Electric Cyan:  #06B6D4
Light Cyan:     #22D3EE
```

## Installation Path

```
/usr/share/backgrounds/cortex/
├── minimal-dark.png    (default)
└── circuit-board.png

/usr/share/gnome-background-properties/
└── cortex-wallpapers.xml
```

## Default Wallpaper

`minimal-dark.png` is set as the default wallpaper via GNOME dconf configuration.

## Asset Generation

```bash
cd packages/cortex-branding
make          # Only rebuild changed assets
make clean    # Remove generated assets
make all      # Force rebuild everything
```
