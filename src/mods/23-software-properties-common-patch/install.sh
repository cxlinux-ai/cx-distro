set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Patching /usr/bin/add-apt-repository to always identify as Ubuntu..."
sudo sed -i.bak "/self.distro = get_distro()/a \        self.distro.id = 'ubuntu' # Patched" /usr/bin/add-apt-repository
judge "Patch /usr/bin/add-apt-repository"
#software-properties-common

print_ok "Linking ubuntu templates and distro info for python-apt..."
sudo ln -sf /usr/share/python-apt/templates/ubuntu.info /usr/share/python-apt/templates/cx.info
sudo ln -sf /usr/share/distro-info/ubuntu.csv /usr/share/distro-info/cx.csv
judge "Link ubuntu templates and distro info for python-apt"

print_ok "Marking software-properties-common as held..."
apt-mark hold software-properties-common
judge "Mark software-properties-common as held"

print_ok "Marking software-properties-common as not upgradeable..."
cat << EOF > /etc/apt/preferences.d/no-upgrade-software-properties-common
Package: software-properties-common
Pin: release o=Ubuntu
Pin-Priority: -1
EOF
judge "Create PIN file for software-properties-common"
