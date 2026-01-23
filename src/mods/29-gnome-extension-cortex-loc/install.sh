set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Install Gnome Extension Cortex Location Switcher"
cp ./loc@cortex.com /usr/share/gnome-shell/extensions/loc@cortex.com -rf
judge "Install Gnome Extension Cortex Location Switcher"