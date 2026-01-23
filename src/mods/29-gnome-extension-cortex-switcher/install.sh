set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Install Gnome Extension Cortex Switcher"
<<<<<<< HEAD
cp ./switcher@cortexlinux /usr/share/gnome-shell/extensions/switcher@cortexlinux -rf
=======
cp ./switcher@cortex /usr/share/gnome-shell/extensions/switcher@cortex -rf
>>>>>>> 4c950da (v2)
judge "Install Gnome Extension Cortex Switcher"