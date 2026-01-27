set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# print_ok "Building deskmon.c"
# sudo apt install pkgconf gcc
# gcc -O2 $(pkg-config --cflags glib-2.0 gio-2.0) deskmon.c -o deskmon $(pkg-config --libs glib-2.0 gio-2.0)
# judge "Build deskmon.c"

print_ok "Installing deskmon"
sudo mv ./deskmon /usr/local/bin/deskmon
sudo chmod +x /usr/local/bin/deskmon
judge "Install deskmon"

print_ok "Installing deskmon.service"
sudo install -D deskmon.service /etc/systemd/user/deskmon.service
sudo mkdir -p /etc/systemd/user/default.target.wants
sudo ln -s /etc/systemd/user/deskmon.service \
         /etc/systemd/user/default.target.wants/deskmon.service
judge "Install deskmon.service"