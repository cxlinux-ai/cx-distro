set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Adding new command to this OS: do-cortex-autorepair..."
cp ./do-cortex-autorepair.sh /usr/local/bin/do-cortex-autorepair
chmod +x /usr/local/bin/do-cortex-autorepair
judge "Add new command do-cortex-autorepair"
