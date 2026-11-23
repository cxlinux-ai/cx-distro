set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Enabling gnome extensions for root..."

pipx ensurepath
PIPX_BIN_DIR=$(pipx environment --value PIPX_BIN_DIR)
export PATH="$PIPX_BIN_DIR:$PATH"
judge "Ensure pipx binaries are in PATH"

# Verify gext is available
if ! command -v gext &> /dev/null; then
    print_error "gext command not found"
    exit 1
fi

gext -F enable arcmenu@arcmenu.com
gext -F enable blur-my-shell@aunetx
gext -F enable ProxySwitcher@flannaghan.com
gext -F enable customize-ibus@hollowman.ml
gext -F enable dash-to-panel@jderose9.github.com
gext -F enable network-stats@gnome.noroadsleft.xyz
gext -F enable simple-weather@romanlefler.com
gext -F enable switcher@cxlinux
gext -F enable noti-bottom-right@cxlinux
gext -F enable loc@cxlinux.com
gext -F enable lockkeys@vaina.lt
gext -F enable tiling-assistant@leleat-on-github
gext -F enable mediacontrols@cliffniff.github.com
gext -F enable clipboard-indicator@tudmotu.com
judge "Enable gnome extensions"

# Install jq:
print_ok "Updating gnome extensions to force enable for gnome 49..."
apt install $INTERACTIVE jq --no-install-recommends
find /usr/share/gnome-shell/extensions -type f -name metadata.json | while IFS= read -r file; do
    if jq -e 'has("shell-version")' "$file" > /dev/null; then
        if jq -e '.["shell-version"] | index("49")' "$file" > /dev/null; then
            print_info "$file already supports gnome \"49\"."
        else
            print_warn "$file does not contain \"49\", updating file..."
            tmpfile=$(mktemp)
            jq '.["shell-version"] += ["49"]' "$file" > "$tmpfile" && mv "$tmpfile" "$file"
            chmod 644 "$file"
        fi
    else
        print_error "$file does not contain \"shell-version\"!"
        exit 1
    fi
done