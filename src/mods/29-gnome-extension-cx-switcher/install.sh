set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Install Gnome Extension CX Switcher"
cp ./switcher@cxlinux /usr/share/gnome-shell/extensions/switcher@cxlinux -rf
judge "Install Gnome Extension CX Switcher"