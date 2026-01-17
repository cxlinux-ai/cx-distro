# GDM Branding

Cortex Linux GDM (GNOME Display Manager) branding is included in the `cortex-branding` package.

## Automatic Installation

GDM branding is automatically configured when you install the package:

```bash
sudo apt install ./cortex-branding_*.deb
# or
sudo dpkg -i cortex-branding_*.deb
```

The package includes:

| Component | Installed To | Description |
|-----------|--------------|-------------|
| GDM CSS theme | `/usr/share/gnome-shell/theme/Cortex/gnome-shell.css` | Login screen styling |
| GDM dconf | `/etc/dconf/db/gdm.d/01-cortex-branding` | GDM settings (logo, banner) |
| Logo SVG | `/usr/share/cortex/logos/cortex-logo-light.svg` | Login screen logo |
| Background | `/usr/share/backgrounds/cortex/minimal-dark.png` | Login background |

## What Gets Configured

The package's `postinst` script:
1. Registers the Cortex GDM theme with `update-alternatives`
2. Updates the dconf database for GDM settings
3. Compiles GSettings schemas

## Manual Testing

After installation:

```bash
# Restart GDM to apply changes
sudo systemctl restart gdm3

# Or switch to tty and back
# Ctrl+Alt+F3, login, then: sudo systemctl restart gdm3
```

## Troubleshooting

### Changes not appearing
1. Clear GDM cache: `sudo rm -rf /var/lib/gdm3/.cache`
2. Rebuild dconf: `sudo dconf update`
3. Restart GDM: `sudo systemctl restart gdm3`

### Login screen shows Debian branding
1. Check alternatives: `update-alternatives --display gdm3-theme.css`
2. Ensure Cortex theme has highest priority

### Reverting to default
```bash
sudo apt remove cortex-branding
# or manually:
sudo update-alternatives --remove gdm3-theme.css /usr/share/gnome-shell/theme/Cortex/gnome-shell.css
sudo dconf update
sudo systemctl restart gdm3
```

## Customizing

To modify GDM theming, edit the files in `packages/cortex-branding/`:
- `usr/share/gnome-shell/theme/Cortex/gnome-shell.css` - CSS styling
- `etc/dconf/db/gdm.d/01-cortex-branding` - GDM dconf settings

Then rebuild the package:
```bash
cd packages/cortex-branding
dpkg-buildpackage -us -uc -b
```
