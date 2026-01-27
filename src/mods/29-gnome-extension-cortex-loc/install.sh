set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Install Gnome Extension Cortex Location Switcher"
cp ./loc@cortexlinux.com /usr/share/gnome-shell/extensions/loc@cortexlinux.com -rf
judge "Install Gnome Extension Cortex Location Switcher"