set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Install Gnome Extension Notification Bottom Right"
<<<<<<< HEAD
cp ./noti-bottom-right@cortexlinux /usr/share/gnome-shell/extensions/noti-bottom-right@cortexlinux -rf
=======
cp ./noti-bottom-right@cortex /usr/share/gnome-shell/extensions/noti-bottom-right@cortex -rf
>>>>>>> 4c950da (v2)
judge "Install Gnome Extension Notification Bottom Right"