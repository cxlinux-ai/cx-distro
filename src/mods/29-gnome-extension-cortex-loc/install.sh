set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Install Gnome Extension Cortex Location Switcher"
<<<<<<< HEAD
<<<<<<< HEAD
cp ./loc@cortexlinux.com /usr/share/gnome-shell/extensions/loc@cortexlinux.com -rf
=======
cp ./loc@cortex.com /usr/share/gnome-shell/extensions/loc@cortex.com -rf
>>>>>>> 4c950da (v2)
=======
cp ./loc@cortexlinux.com /usr/share/gnome-shell/extensions/loc@cortexlinux.com -rf
>>>>>>> ccdc3d4 (Remove obsolete documentation and update installation scripts for Cortex Linux)
judge "Install Gnome Extension Cortex Location Switcher"