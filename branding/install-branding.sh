#!/bin/bash
#
# Cortex Linux Branding Installer
#
# This script installs Cortex Linux branding components.
# Run with sudo for system-wide installation.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANDING_DIR="${SCRIPT_DIR}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (sudo)"
        exit 1
    fi
}

# Install OS release files
install_os_release() {
    log_info "Installing OS identity files..."

    # Backup originals
    [ -f /etc/os-release ] && cp /etc/os-release /etc/os-release.debian-backup
    [ -f /etc/lsb-release ] && cp /etc/lsb-release /etc/lsb-release.debian-backup
    [ -f /etc/issue ] && cp /etc/issue /etc/issue.debian-backup
    [ -f /etc/issue.net ] && cp /etc/issue.net /etc/issue.net.debian-backup

    # Install Cortex versions
    cp "${BRANDING_DIR}/os-release/os-release" /etc/os-release
    cp "${BRANDING_DIR}/os-release/lsb-release" /etc/lsb-release
    cp "${BRANDING_DIR}/os-release/issue" /etc/issue
    cp "${BRANDING_DIR}/os-release/issue.net" /etc/issue.net

    log_success "OS identity files installed"
}

# Install Plymouth theme
install_plymouth() {
    log_info "Installing Plymouth boot theme..."

    if ! command -v plymouth &>/dev/null; then
        log_warn "Plymouth not installed, skipping"
        return
    fi

    mkdir -p /usr/share/plymouth/themes/cortex
    cp -r "${BRANDING_DIR}/plymouth/cortex/"* /usr/share/plymouth/themes/cortex/

    # Check for required image assets
    if [ ! -f /usr/share/plymouth/themes/cortex/logo.png ]; then
        log_warn "Plymouth logo.png not found - theme may not display correctly"
        log_warn "Please add image assets as described in ASSETS.md"
    fi

    # Set as default theme
    plymouth-set-default-theme cortex 2>/dev/null || true
    update-initramfs -u 2>/dev/null || true

    log_success "Plymouth theme installed"
}

# Install GRUB theme
install_grub() {
    log_info "Installing GRUB theme..."

    mkdir -p /boot/grub/themes/cortex
    cp -r "${BRANDING_DIR}/grub/cortex/"* /boot/grub/themes/cortex/

    # Check for required image assets
    if [ ! -f /boot/grub/themes/cortex/background.png ]; then
        log_warn "GRUB background.png not found - using default dark background"
    fi

    # Update GRUB config
    if [ -f /etc/default/grub ]; then
        if grep -q "^GRUB_THEME=" /etc/default/grub; then
            sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/cortex/theme.txt"|' /etc/default/grub
        else
            echo 'GRUB_THEME="/boot/grub/themes/cortex/theme.txt"' >> /etc/default/grub
        fi
        update-grub 2>/dev/null || true
    fi

    log_success "GRUB theme installed"
}

# Install wallpapers
install_wallpapers() {
    log_info "Installing desktop wallpapers..."

    mkdir -p /usr/share/backgrounds/cortex
    mkdir -p /usr/share/gnome-background-properties

    # Copy wallpaper XML
    cp "${BRANDING_DIR}/wallpapers/cortex-wallpapers.xml" \
        /usr/share/gnome-background-properties/

    # Check for wallpaper images
    if [ -d "${BRANDING_DIR}/wallpapers/images" ]; then
        cp "${BRANDING_DIR}/wallpapers/images/"*.png \
            /usr/share/backgrounds/cortex/ 2>/dev/null || true
    else
        log_warn "Wallpaper images not found in wallpapers/images/"
        log_warn "Please add PNG files as described in ASSETS.md"
    fi

    log_success "Wallpapers installed"
}

# Install GDM branding
install_gdm() {
    log_info "Installing GDM login branding..."

    if ! command -v gdm3 &>/dev/null && ! [ -d /etc/gdm3 ]; then
        log_warn "GDM not found, skipping"
        return
    fi

    # Copy GDM config
    if [ -d /etc/gdm3 ]; then
        cp "${BRANDING_DIR}/gdm/gdm-branding.conf" \
            /etc/gdm3/greeter.dconf-defaults
        dconf update 2>/dev/null || true
    fi

    log_success "GDM branding installed"
}

# Install MOTD
install_motd() {
    log_info "Installing terminal MOTD..."

    mkdir -p /etc/update-motd.d

    # Disable existing MOTD scripts
    for f in /etc/update-motd.d/*; do
        [ -f "$f" ] && chmod -x "$f" 2>/dev/null || true
    done

    # Install Cortex MOTD scripts
    cp "${BRANDING_DIR}/motd/00-cortex-banner" /etc/update-motd.d/
    cp "${BRANDING_DIR}/motd/10-cortex-sysinfo" /etc/update-motd.d/
    cp "${BRANDING_DIR}/motd/20-cortex-updates" /etc/update-motd.d/
    cp "${BRANDING_DIR}/motd/99-cortex-footer" /etc/update-motd.d/

    chmod +x /etc/update-motd.d/00-cortex-banner
    chmod +x /etc/update-motd.d/10-cortex-sysinfo
    chmod +x /etc/update-motd.d/20-cortex-updates
    chmod +x /etc/update-motd.d/99-cortex-footer

    log_success "MOTD installed"
}

# Install neofetch config
install_neofetch() {
    log_info "Installing neofetch configuration..."

    if ! command -v neofetch &>/dev/null; then
        log_warn "neofetch not installed, skipping"
        return
    fi

    mkdir -p /etc/neofetch
    cp "${BRANDING_DIR}/neofetch/config.conf" /etc/neofetch/config.conf

    # Install custom ASCII art
    mkdir -p /usr/share/neofetch/ascii/distro
    cp "${BRANDING_DIR}/neofetch/cortex.txt" /usr/share/neofetch/ascii/distro/cortex

    log_success "Neofetch configuration installed"
}

# Main installation
main() {
    echo ""
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║          Cortex Linux Branding Installer                      ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    check_root

    install_os_release
    install_plymouth
    install_grub
    install_wallpapers
    install_gdm
    install_motd
    install_neofetch

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Cortex Linux branding installation complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Some changes require a reboot to take effect:"
    echo "    - Plymouth boot splash"
    echo "    - GRUB theme"
    echo "    - GDM login screen"
    echo ""
    echo "  To reboot now: sudo reboot"
    echo ""
}

# Run main
main "$@"
