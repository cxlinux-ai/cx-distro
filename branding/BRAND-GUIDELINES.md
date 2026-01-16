# Cortex Linux Brand Guidelines

Official brand guidelines for Cortex Linux visual identity.

## Brand Essence

Cortex Linux is an AI-powered Linux distribution that combines the stability of Debian with cutting-edge AI capabilities. The brand should convey:

- **Intelligence** - Neural networks, AI, machine learning
- **Power** - Professional, capable, enterprise-ready
- **Elegance** - Modern, clean, minimal
- **Trust** - Reliable, secure, stable

## Logo

### Primary Logo

The Cortex logo is a "CX" monogram in a circular badge, featuring:
- **CX monogram**: Bold, stylized letters representing "Cortex"
- **Circular badge**: A ring with a purple-to-cyan gradient (matching the brand color palette)
- **Circuit board traces**: Horizontal lines extending from the badge, representing technology and connectivity
- **Two versions**: Light version (white/light background) and Dark version (dark space-like background)

The design conveys:
- AI and machine learning capabilities through the circuit aesthetics
- Modern, tech-forward identity fitting the "Cortex" name
- Professional and enterprise-ready appearance

### Logo Variations

| Variant | Usage |
|---------|-------|
| Full color (dark bg) | Primary use on dark backgrounds |
| Full color (light bg) | Light backgrounds |
| Transparent | Overlay on images or colored backgrounds |
| Icon only | Favicons, app icons, small contexts |

### Source Files

Master logo files are located in `branding/source/`:
- `cx-logo-dark.png` - Logo on dark space-like background
- `cx-logo-transparent.png` - Logo with transparent background

### Clear Space

Maintain minimum clear space equal to the height of the "O" in CORTEX around all sides of the logo.

### Minimum Size

- Full logo: 120px width minimum
- Icon only: 24px minimum

## Color Palette

### Primary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Cortex Purple** | `#6B21A8` | 107, 33, 168 | Primary brand color |
| **Electric Cyan** | `#06B6D4` | 6, 182, 212 | Accent, highlights |
| **Deep Space** | `#0F0F23` | 15, 15, 35 | Dark backgrounds |

### Secondary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Light Purple | `#A855F7` | 168, 85, 247 | Hover states, gradients |
| Dark Purple | `#4C1D95` | 76, 29, 149 | Shadows, depth |
| Light Cyan | `#22D3EE` | 34, 211, 238 | Highlights, active states |
| Dark Cyan | `#0891B2` | 8, 145, 178 | Pressed states |

### Neutral Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| White | `#FFFFFF` | 255, 255, 255 | Light text, backgrounds |
| Light Gray | `#F8FAFC` | 248, 250, 252 | Light mode backgrounds |
| Gray 100 | `#E2E8F0` | 226, 232, 240 | Borders, dividers |
| Gray 300 | `#94A3B8` | 148, 163, 184 | Muted text |
| Gray 500 | `#64748B` | 100, 116, 139 | Secondary text |
| Gray 700 | `#334155` | 51, 65, 85 | Dark mode text |
| Dark Gray | `#1E1E3F` | 30, 30, 63 | Dark surfaces |
| Black | `#0A0A18` | 10, 10, 24 | Deepest dark |

### Semantic Colors

| Name | Hex | Usage |
|------|-----|-------|
| Success | `#10B981` | Positive actions, confirmations |
| Warning | `#FBBF24` | Caution, attention needed |
| Error | `#EF4444` | Errors, destructive actions |
| Info | `#3B82F6` | Informational messages |

## Typography

### System Fonts

```css
/* Sans-serif (UI, body text) */
font-family: 'Inter', 'Segoe UI', 'Roboto', sans-serif;

/* Monospace (code, terminal) */
font-family: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace;
```

### Font Weights

- **Light (300)**: Large headings
- **Regular (400)**: Body text
- **Medium (500)**: Subheadings
- **Semibold (600)**: Buttons, labels
- **Bold (700)**: Headings, emphasis

### Scale

| Name | Size | Line Height | Usage |
|------|------|-------------|-------|
| Display | 48px | 1.1 | Hero headings |
| H1 | 36px | 1.2 | Page titles |
| H2 | 28px | 1.3 | Section headings |
| H3 | 22px | 1.4 | Subsections |
| Body | 16px | 1.5 | Paragraphs |
| Small | 14px | 1.5 | Captions |
| Tiny | 12px | 1.4 | Labels |

## Iconography

### Style

- Line weight: 1.5px
- Corner radius: 2px
- Grid: 24x24 base
- Style: Rounded, modern

### System Icons

Use Lucide icons or similar for consistency:
- Simple, recognizable
- Consistent stroke weight
- Rounded corners

## Gradients

### Primary Gradient
```css
background: linear-gradient(135deg, #6B21A8 0%, #06B6D4 100%);
```

### Dark Gradient
```css
background: linear-gradient(180deg, #0F0F23 0%, #0A0A18 100%);
```

### Subtle Gradient (for cards)
```css
background: linear-gradient(135deg, #1E1E3F 0%, #0F0F23 100%);
```

## Components

### Buttons

```
Primary: #6B21A8 background, white text
Secondary: transparent, #6B21A8 border
Ghost: transparent, #94A3B8 text
Danger: #EF4444 background, white text
```

### Cards

```
Background: #1E1E3F (dark) or #FFFFFF (light)
Border: 1px solid rgba(107, 33, 168, 0.2)
Border radius: 12px
Shadow: 0 4px 20px rgba(0, 0, 0, 0.15)
```

### Input Fields

```
Background: #0F0F23 (dark) or #F8FAFC (light)
Border: 1px solid #2D2D5A
Focus border: #06B6D4
Border radius: 8px
```

## Animation

### Timing

- **Fast**: 150ms (hover, focus)
- **Normal**: 250ms (transitions)
- **Slow**: 400ms (complex animations)

### Easing

```css
/* Default */
transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);

/* Enter */
transition-timing-function: cubic-bezier(0, 0, 0.2, 1);

/* Exit */
transition-timing-function: cubic-bezier(0.4, 0, 1, 1);
```

## Usage Examples

### Dark Theme (Default)

```css
:root {
    --bg-primary: #0F0F23;
    --bg-secondary: #1E1E3F;
    --text-primary: #E2E8F0;
    --text-secondary: #94A3B8;
    --accent-primary: #6B21A8;
    --accent-secondary: #06B6D4;
}
```

### Light Theme

```css
:root {
    --bg-primary: #FFFFFF;
    --bg-secondary: #F8FAFC;
    --text-primary: #0F172A;
    --text-secondary: #64748B;
    --accent-primary: #6B21A8;
    --accent-secondary: #0891B2;
}
```

## File Formats

### Logos
- SVG: Primary format for web/print
- PNG: Raster fallback (2x, 3x)
- ICO: Favicons

### Images
- PNG: Screenshots, complex graphics
- WebP: Web optimization
- JPEG: Photos (quality 85%)

## Don'ts

- Don't stretch or distort the logo
- Don't change logo colors arbitrarily
- Don't add effects (shadows, glows) to logo
- Don't place logo on busy backgrounds
- Don't use unapproved color combinations
- Don't use fonts outside the family
