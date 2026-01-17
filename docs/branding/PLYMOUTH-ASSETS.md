# Plymouth Theme Assets

Minimal Cortex Linux Plymouth theme - CX logo centered on pure black background.

## Required Files

| File | Dimensions | Description |
|------|------------|-------------|
| `logo.png` | 300x300 | CX logo with purple-cyan gradient ring |
| `entry.png` | 300x40 | Password entry box (shown when needed) |
| `bullet.png` | 15x15 | Password bullet character |

## Design

- **Background**: Pure black (#000000)
- **Logo**: CX monogram with gradient ring, perfectly centered
- **No animations, no progress bar, no wordmark** - clean minimal boot splash

## Asset Generation

Assets are generated from `packages/cortex-branding/source/cx-logo-primary.png` using Make.

```bash
cd packages/cortex-branding
make          # Only rebuild changed assets
make clean    # Remove generated assets
make all      # Force rebuild everything
```
