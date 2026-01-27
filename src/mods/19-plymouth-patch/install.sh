set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Patch plymouth"
cp ./logo_128.png      /usr/share/plymouth/themes/spinner/bgrt-fallback.png
cp ./cortex_text.png /usr/share/plymouth/ubuntu-logo.png
cp ./cortex_text.png /usr/share/plymouth/themes/spinner/watermark.png
#update-initramfs -u # We don't have to update initramfs here, because we did it in the end of this script
judge "Patch plymouth and update initramfs"

# hold theme spinner to be upgraded
print_ok "Marking plymouth-theme-spinner as held..."
apt-mark hold plymouth-theme-spinner
judge "Mark plymouth-theme-spinner as held"

print_ok "Marking plymouth-theme-spinner as not upgradeable..."
cat << EOF > /etc/apt/preferences.d/no-upgrade-plymouth-theme-spinner
Package: plymouth-theme-spinner
Pin: release o=Ubuntu
Pin-Priority: -1
EOF
judge "Create PIN file for plymouth-theme-spinner"

# Install custom cx-boot-animation theme
print_ok "Installing cx-boot-animation Plymouth theme..."
THEME_DIR="/usr/share/plymouth/themes/cx-boot-animation"
mkdir -p "$THEME_DIR"
judge "Create theme directory"

print_ok "Copying animation frames..."
cp ./frames/frame_*.png "$THEME_DIR/"
judge "Copy animation frames"

print_ok "Copying theme files..."
cp ./cx-boot-animation.plymouth "$THEME_DIR/"
cp ./cx-boot-animation.script "$THEME_DIR/"
judge "Copy theme files"

print_ok "Installing cx-boot-animation theme via update-alternatives..."
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$THEME_DIR/cx-boot-animation.plymouth" 100
judge "Install theme via update-alternatives"

print_ok "Setting cx-boot-animation as default theme..."
update-alternatives --set default.plymouth "$THEME_DIR/cx-boot-animation.plymouth"
judge "Set cx-boot-animation as default theme"
