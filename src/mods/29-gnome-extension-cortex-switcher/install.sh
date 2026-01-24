set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Install Gnome Extension Cortex Switcher"
<<<<<<< HEAD
<<<<<<< HEAD
cp ./switcher@cortexlinux /usr/share/gnome-shell/extensions/switcher@cortexlinux -rf
=======
cp ./switcher@cortex /usr/share/gnome-shell/extensions/switcher@cortex -rf
>>>>>>> 4c950da (v2)
=======
cp ./switcher@cortexlinux /usr/share/gnome-shell/extensions/switcher@cortexlinux -rf
>>>>>>> ccdc3d4 (Remove obsolete documentation and update installation scripts for Cortex Linux)
judge "Install Gnome Extension Cortex Switcher"