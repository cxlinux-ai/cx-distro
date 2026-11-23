set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Install Gnome Extension CX Location Switcher"
cp ./loc@cxlinux.com /usr/share/gnome-shell/extensions/loc@cxlinux.com -rf
judge "Install Gnome Extension CX Location Switcher"