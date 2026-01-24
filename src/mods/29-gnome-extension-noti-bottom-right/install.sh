set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Install Gnome Extension Notification Bottom Right"
<<<<<<< HEAD
<<<<<<< HEAD
cp ./noti-bottom-right@cortexlinux /usr/share/gnome-shell/extensions/noti-bottom-right@cortexlinux -rf
=======
cp ./noti-bottom-right@cortex /usr/share/gnome-shell/extensions/noti-bottom-right@cortex -rf
>>>>>>> 4c950da (v2)
=======
cp ./noti-bottom-right@cortexlinux /usr/share/gnome-shell/extensions/noti-bottom-right@cortexlinux -rf
>>>>>>> ccdc3d4 (Remove obsolete documentation and update installation scripts for Cortex Linux)
judge "Install Gnome Extension Notification Bottom Right"