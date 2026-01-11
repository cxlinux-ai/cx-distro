#!/bin/bash
#
# Cortex Linux First-Boot Provisioning Script
#
# This script runs once at first boot to complete system setup.
# It is designed to be:
#   - Idempotent: Safe to run multiple times
#   - Offline-capable: Core functionality works without network
#   - Profile-aware: Different actions for core/full/secops
#
# Exit codes:
#   0 - Success
#   1 - General error
#   2 - Profile not found
#   3 - Required command missing
#

set -euo pipefail

readonly CORTEX_DIR="/opt/cortex"
readonly PROVISION_DIR="${CORTEX_DIR}/provisioning"
readonly LOG_DIR="/var/log/cortex"
readonly LOG_FILE="${LOG_DIR}/first-boot.log"
readonly STATE_FILE="${PROVISION_DIR}/.first-boot-complete"
readonly PROFILE_FILE="${PROVISION_DIR}/profile"

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

# Check if already completed
check_already_complete() {
    if [[ -f "${STATE_FILE}" ]]; then
        log_info "First-boot provisioning already completed. Exiting."
        exit 0
    fi
}

# Initialize logging
init_logging() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    chmod 640 "${LOG_FILE}"
    log_info "=== Cortex Linux First-Boot Provisioning Started ==="
    log_info "Hostname: $(hostname)"
    log_info "Date: $(date)"
    log_info "Kernel: $(uname -r)"
}

# Load profile configuration
load_profile() {
    if [[ ! -f "${PROFILE_FILE}" ]]; then
        log_warn "Profile file not found, defaulting to 'core'"
        CORTEX_PROFILE="core"
    else
        # shellcheck source=/dev/null
        source "${PROFILE_FILE}"
    fi

    log_info "Profile: ${CORTEX_PROFILE:-core}"
    export CORTEX_PROFILE="${CORTEX_PROFILE:-core}"
}

# Check network connectivity (non-blocking)
check_network() {
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        log_info "Network: Online"
        export NETWORK_AVAILABLE=true
    else
        log_warn "Network: Offline (some features may be skipped)"
        export NETWORK_AVAILABLE=false
    fi
}

# Generate machine-id if not present
setup_machine_id() {
    log_info "Setting up machine-id..."

    if [[ ! -s /etc/machine-id ]]; then
        systemd-machine-id-setup
        log_info "Generated new machine-id"
    else
        log_info "Machine-id already exists"
    fi
}

# Configure sudo for cortex user
setup_sudo() {
    log_info "Configuring sudo..."

    local sudoers_file="/etc/sudoers.d/cortex"

    if [[ ! -f "${sudoers_file}" ]]; then
        cat > "${sudoers_file}" << 'EOF'
# Cortex Linux sudo configuration
# Allow cortex user to run sudo with password
cortex ALL=(ALL:ALL) ALL

# Secure defaults
Defaults    env_reset
Defaults    mail_badpass
Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults    use_pty
Defaults    logfile="/var/log/sudo.log"
EOF
        chmod 440 "${sudoers_file}"
        log_info "Sudo configured for cortex user"
    else
        log_info "Sudo already configured"
    fi
}

# Force password change on first login
setup_password_change() {
    if [[ "${REQUIRE_PASSWORD_CHANGE:-false}" == "true" ]]; then
        log_info "Forcing password change on first login..."
        chage -d 0 cortex
        log_info "Password change required for cortex user"
    fi
}

# Configure SSH hardening
setup_ssh() {
    log_info "Configuring SSH..."

    local sshd_config="/etc/ssh/sshd_config.d/cortex-hardening.conf"

    if [[ ! -f "${sshd_config}" ]]; then
        mkdir -p /etc/ssh/sshd_config.d
        cat > "${sshd_config}" << 'EOF'
# Cortex Linux SSH Hardening
# Disable root login
PermitRootLogin no

# Disable password authentication for root
PasswordAuthentication yes
PubkeyAuthentication yes

# Disable empty passwords
PermitEmptyPasswords no

# Limit authentication attempts
MaxAuthTries 3

# Disable X11 forwarding (enable if needed)
X11Forwarding no

# Client alive settings
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable TCP forwarding by default
AllowTcpForwarding no

# Use strong ciphers only
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com

# Use strong MACs
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Use strong key exchange
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
EOF
        chmod 644 "${sshd_config}"
        log_info "SSH hardening configured"

        # Reload SSH if running
        if systemctl is-active --quiet sshd; then
            systemctl reload sshd || true
        fi
    else
        log_info "SSH hardening already configured"
    fi
}

# Configure firewall (UFW)
setup_firewall() {
    log_info "Configuring firewall..."

    if command -v ufw &>/dev/null; then
        # Check if UFW is already configured
        if ! ufw status | grep -q "Status: active"; then
            # Default policies
            ufw default deny incoming
            ufw default allow outgoing

            # Allow SSH
            ufw allow ssh

            # Enable UFW
            echo "y" | ufw enable
            log_info "UFW firewall enabled"
        else
            log_info "UFW already active"
        fi
    else
        log_warn "UFW not installed, skipping firewall configuration"
    fi
}

# Configure fail2ban
setup_fail2ban() {
    log_info "Configuring fail2ban..."

    if command -v fail2ban-client &>/dev/null; then
        local jail_local="/etc/fail2ban/jail.local"

        if [[ ! -f "${jail_local}" ]]; then
            cat > "${jail_local}" << 'EOF'
# Cortex Linux fail2ban configuration
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

# Email notifications (configure if needed)
# destemail = admin@example.com
# sendername = Fail2Ban
# mta = sendmail

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
EOF
            chmod 644 "${jail_local}"
            systemctl enable fail2ban
            systemctl restart fail2ban
            log_info "fail2ban configured and enabled"
        else
            log_info "fail2ban already configured"
        fi
    else
        log_warn "fail2ban not installed, skipping"
    fi
}

# Configure automatic security updates
setup_unattended_upgrades() {
    log_info "Configuring automatic security updates..."

    if command -v unattended-upgrade &>/dev/null; then
        local auto_upgrades="/etc/apt/apt.conf.d/20auto-upgrades"

        if [[ ! -f "${auto_upgrades}" ]]; then
            cat > "${auto_upgrades}" << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF
            log_info "Automatic security updates enabled"
        else
            log_info "Automatic updates already configured"
        fi
    else
        log_warn "unattended-upgrades not installed, skipping"
    fi
}

# Profile-specific: SecOps hardening
secops_hardening() {
    log_info "Applying SecOps security hardening..."

    # Enable AppArmor
    if command -v aa-status &>/dev/null; then
        systemctl enable apparmor
        systemctl start apparmor || true
        log_info "AppArmor enabled"
    fi

    # Enable auditd
    if command -v auditd &>/dev/null; then
        systemctl enable auditd
        systemctl start auditd || true
        log_info "Audit daemon enabled"
    fi

    # Initialize AIDE database (offline-safe)
    if command -v aide &>/dev/null; then
        if [[ ! -f /var/lib/aide/aide.db ]]; then
            log_info "Initializing AIDE database (this may take a while)..."
            if aide --init; then
                if [[ -f /var/lib/aide/aide.db.new ]]; then
                    mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
                    log_info "AIDE database initialized"
                fi
            else
                log_warn "AIDE initialization failed (non-critical)"
            fi
        fi
    fi

    # Configure kernel hardening via sysctl
    local sysctl_hardening="/etc/sysctl.d/99-cortex-hardening.conf"
    if [[ ! -f "${sysctl_hardening}" ]]; then
        cat > "${sysctl_hardening}" << 'EOF'
# Cortex Linux Kernel Hardening

# Disable IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Enable SYN flood protection
net.ipv4.tcp_syncookies = 1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1

# Ignore ICMP broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Log martian packets
net.ipv4.conf.all.log_martians = 1

# Disable core dumps for setuid programs
fs.suid_dumpable = 0

# Restrict kernel pointer exposure
kernel.kptr_restrict = 2

# Restrict dmesg access
kernel.dmesg_restrict = 1

# Restrict perf access
kernel.perf_event_paranoid = 3

# Enable ASLR
kernel.randomize_va_space = 2

# Restrict ptrace
kernel.yama.ptrace_scope = 1
EOF
        chmod 644 "${sysctl_hardening}"
        sysctl --system &>/dev/null || true
        log_info "Kernel hardening applied"
    fi

    # Warn about FDE passphrase change
    if [[ "${REQUIRE_FDE_PASSPHRASE_CHANGE:-false}" == "true" ]]; then
        log_warn "IMPORTANT: FDE passphrase change required!"
        log_warn "Run: sudo cryptsetup luksChangeKey /dev/sda3"

        # Create reminder file
        cat > /home/cortex/SECURITY-NOTICE.txt << 'EOF'
===============================================================================
                    CORTEX LINUX SECURITY NOTICE
===============================================================================

Your system is configured with Full Disk Encryption (FDE).

IMPORTANT: The current encryption passphrase is a temporary default.
You MUST change it immediately for security.

To change the FDE passphrase:
    sudo cryptsetup luksChangeKey /dev/sda3

To verify encryption status:
    sudo cryptsetup status cortex-sec-vg

For more information, see the Cortex Linux Security Guide.

===============================================================================
EOF
        chown cortex:cortex /home/cortex/SECURITY-NOTICE.txt
    fi
}

# Profile-specific: Full desktop setup
full_desktop_setup() {
    log_info "Configuring full desktop environment..."

    # Add Flathub repository if flatpak is installed
    if command -v flatpak &>/dev/null && [[ "${NETWORK_AVAILABLE}" == "true" ]]; then
        if ! flatpak remote-list | grep -q flathub; then
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
            log_info "Flathub repository added"
        fi
    fi

    # Configure Docker for cortex user
    if command -v docker &>/dev/null; then
        if ! groups cortex | grep -q docker; then
            usermod -aG docker cortex
            log_info "Added cortex user to docker group"
        fi
    fi
}

# Add Cortex repository (requires network)
setup_cortex_repository() {
    if [[ "${NETWORK_AVAILABLE}" != "true" ]]; then
        log_warn "Network unavailable, skipping Cortex repository setup"
        return 0
    fi

    log_info "Setting up Cortex package repository..."

    local keyring_dir="/usr/share/keyrings"
    local sources_file="/etc/apt/sources.list.d/cortex-linux.list"

    # Check if already configured (from live image or previous run)
    if [[ -f "${sources_file}" ]]; then
        log_info "Cortex repository already configured"
        return 0
    fi

    log_info "Adding Cortex Linux APT repository..."

    # Download and install GPG key
    if curl -fsSL https://apt.cortexlinux.com/keys/cortex-linux.gpg.asc | gpg --dearmor -o "${keyring_dir}/cortex-linux.gpg"; then
        log_info "Cortex GPG key installed"
    else
        log_error "Failed to download Cortex GPG key"
        return 1
    fi

    # Add repository source
    echo "deb [signed-by=${keyring_dir}/cortex-linux.gpg] https://apt.cortexlinux.com stable main" > "${sources_file}"

    # Update package lists
    if apt-get update -qq; then
        log_info "Cortex repository configured successfully"
    else
        log_warn "apt-get update failed, repository may not be accessible"
    fi
}

# Generate SSH host keys if missing
setup_ssh_keys() {
    log_info "Checking SSH host keys..."

    local keys_generated=false

    for keytype in rsa ecdsa ed25519; do
        local keyfile="/etc/ssh/ssh_host_${keytype}_key"
        if [[ ! -f "${keyfile}" ]]; then
            ssh-keygen -t "${keytype}" -f "${keyfile}" -N "" -q
            keys_generated=true
            log_info "Generated SSH ${keytype} host key"
        fi
    done

    if [[ "${keys_generated}" == "true" ]]; then
        systemctl restart sshd || true
    fi
}

# Cleanup temporary installation artifacts
cleanup() {
    log_info "Cleaning up installation artifacts..."

    # Remove installer logs that may contain sensitive info
    if [ -d /var/log/installer ]; then
        rm -f /var/log/installer/*
    fi

    # Clear apt cache
    apt-get clean

    log_info "Cleanup complete"
}

# Mark provisioning as complete
mark_complete() {
    local completion_time
    completion_time=$(date '+%Y-%m-%d %H:%M:%S')

    cat > "${STATE_FILE}" << EOF
# Cortex Linux First-Boot Provisioning
# Completed: ${completion_time}
# Profile: ${CORTEX_PROFILE}
# Hostname: $(hostname)
COMPLETED=true
TIMESTAMP=${completion_time}
PROFILE=${CORTEX_PROFILE}
EOF

    chmod 644 "${STATE_FILE}"
    log_info "=== First-Boot Provisioning Complete ==="
}

# Main execution
main() {
    check_already_complete
    init_logging
    load_profile
    check_network

    # Core setup (all profiles)
    setup_machine_id
    setup_sudo
    setup_ssh_keys
    setup_ssh
    setup_password_change

    # Profile-specific setup
    case "${CORTEX_PROFILE}" in
        core)
            log_info "Applying core profile configuration..."
            setup_firewall
            ;;
        full)
            log_info "Applying full profile configuration..."
            setup_firewall
            setup_fail2ban
            setup_unattended_upgrades
            full_desktop_setup
            setup_cortex_repository
            ;;
        secops)
            log_info "Applying secops profile configuration..."
            setup_firewall
            setup_fail2ban
            setup_unattended_upgrades
            secops_hardening
            setup_cortex_repository
            ;;
        *)
            log_warn "Unknown profile: ${CORTEX_PROFILE}, using core defaults"
            setup_firewall
            ;;
    esac

    cleanup
    mark_complete

    # Disable the first-boot service after completion
    if systemctl is-enabled cortex-first-boot.service &>/dev/null; then
        systemctl disable cortex-first-boot.service
    fi

    log_info "System will continue to boot normally."
}

# Run main function
main "$@"
