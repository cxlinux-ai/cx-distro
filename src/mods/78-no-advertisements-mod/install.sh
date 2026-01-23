set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Ensuring Ubuntu Pro advertisement is disabled"
FILE="/etc/apt/apt.conf.d/20apt-esm-hook.conf"
if [[ -e "$FILE" ]]; then
  print_error "Error: $FILE exists, aborting."
  exit 1
fi
judge "Ensure Ubuntu Pro advertisement is disabled"