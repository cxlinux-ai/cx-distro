# GDM Branding Installation

Instructions for installing Cortex Linux GDM branding.

## Files

| File | Destination | Description |
|------|-------------|-------------|
| `cortex-gdm.css` | GDM theme | Main CSS styling |
| `gdm-branding.conf` | `/etc/gdm3/greeter.dconf-defaults` | GDM config |
| `cortex-login-bg.png` | GDM resources | Login background |
| `cortex-logo.svg` | GDM resources | Logo for login screen |

## Installation Steps

### Method 1: Override GDM CSS (Recommended)

```bash
# Backup original theme
sudo cp /usr/share/gnome-shell/theme/gnome-shell.css \
    /usr/share/gnome-shell/theme/gnome-shell.css.backup

# Extract and modify GDM resources
sudo cp /usr/share/gnome-shell/gnome-shell-theme.gresource \
    /usr/share/gnome-shell/gnome-shell-theme.gresource.backup

# Create custom theme directory
sudo mkdir -p /usr/share/gnome-shell/theme/Cortex

# Copy custom CSS
sudo cp cortex-gdm.css /usr/share/gnome-shell/theme/Cortex/gnome-shell.css

# Set as default theme
sudo update-alternatives --install \
    /usr/share/gnome-shell/theme/gnome-shell.css \
    gdm-theme /usr/share/gnome-shell/theme/Cortex/gnome-shell.css 100
```

### Method 2: Using dconf (For settings only)

```bash
# Copy config
sudo cp gdm-branding.conf /etc/gdm3/greeter.dconf-defaults

# Update dconf database
sudo dconf update
```

### Method 3: Full GResource Replacement

For complete control, build a custom gresource:

```bash
# Create resource XML
cat > gnome-shell-theme.gresource.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/org/gnome/shell/theme">
    <file>gnome-shell.css</file>
    <file>cortex-login-bg.png</file>
    <file>cortex-logo.svg</file>
  </gresource>
</gresources>
EOF

# Build resource
glib-compile-resources gnome-shell-theme.gresource.xml

# Install
sudo cp gnome-shell-theme.gresource /usr/share/gnome-shell/
```

## Testing

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
1. Check alternatives: `update-alternatives --display gdm-theme`
2. Ensure Cortex theme has highest priority

### Black screen after changes
1. Boot to recovery mode
2. Restore backup: `sudo cp gnome-shell.css.backup gnome-shell.css`
3. Reboot normally
