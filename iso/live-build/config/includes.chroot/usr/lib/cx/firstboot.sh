#!/bin/bash
# CX Linux First Boot Provisioning
# Runs on first boot to complete system setup
# Copyright 2025 AI Venture Holdings LLC
# SPDX-License-Identifier: BUSL-1.1

set -e

PROVISION_VERSION="1.0.0"
PROVISION_LOG="/var/log/cx/firstboot.log"
STATE_FILE="/etc/cx/.provision-state"
CONFIG_FILE="/etc/cx/provision.yaml"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$PROVISION_LOG"
}

log_section() {
    log "=============================================="
    log "$*"
    log "=============================================="
}

# Error handling
error_exit() {
    log "ERROR: $*"
    exit 1
}

# State management for idempotency
state_get() {
    local key="$1"
    if [ -f "$STATE_FILE" ]; then
        grep "^${key}=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2-
    fi
}

state_set() {
    local key="$1"
    local value="$2"
    mkdir -p "$(dirname "$STATE_FILE")"
    if [ -f "$STATE_FILE" ]; then
        sed -i "/^${key}=/d" "$STATE_FILE"
    fi
    echo "${key}=${value}" >> "$STATE_FILE"
}

state_done() {
    local step="$1"
    state_set "step_${step}" "done"
}

state_check() {
    local step="$1"
    [ "$(state_get "step_${step}")" = "done" ]
}

# =============================================================================
# PROVISIONING STEPS
# =============================================================================

provision_hostname() {
    if state_check "hostname"; then
        log "Hostname already configured, skipping"
        return 0
    fi
    
    log_section "Configuring Hostname"
    
    # Read from provision config or use default
    local hostname="${CX_HOSTNAME:-cx}"
    
    if [ -f "$CONFIG_FILE" ]; then
        local cfg_hostname
        cfg_hostname=$(grep -E "^hostname:" "$CONFIG_FILE" 2>/dev/null | awk '{print $2}')
        [ -n "$cfg_hostname" ] && hostname="$cfg_hostname"
    fi
    
    hostnamectl set-hostname "$hostname"
    log "Hostname set to: $hostname"
    
    state_done "hostname"
}

provision_network() {
    if state_check "network"; then
        log "Network already configured, skipping"
        return 0
    fi
    
    log_section "Configuring Network"
    
    # Network is typically configured via DHCP during install
    # This step validates connectivity
    
    if ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        log "Network connectivity verified"
    else
        log "WARNING: No network connectivity detected"
        log "System will operate in offline mode"
    fi
    
    state_done "network"
}

provision_timezone() {
    if state_check "timezone"; then
        log "Timezone already configured, skipping"
        return 0
    fi
    
    log_section "Configuring Timezone"
    
    local timezone="${CX_TIMEZONE:-UTC}"
    
    if [ -f "$CONFIG_FILE" ]; then
        local cfg_tz
        cfg_tz=$(grep -E "^timezone:" "$CONFIG_FILE" 2>/dev/null | awk '{print $2}')
        [ -n "$cfg_tz" ] && timezone="$cfg_tz"
    fi
    
    timedatectl set-timezone "$timezone"
    log "Timezone set to: $timezone"
    
    state_done "timezone"
}

provision_ssh() {
    if state_check "ssh"; then
        log "SSH already configured, skipping"
        return 0
    fi
    
    log_section "Configuring SSH"
    
    # Ensure SSH is enabled
    systemctl enable ssh
    systemctl start ssh
    
    # Generate host keys if missing
    if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
        log "Regenerating SSH host keys..."
        rm -f /etc/ssh/ssh_host_*
        dpkg-reconfigure openssh-server
    fi
    
    # Inject authorized keys if provided
    if [ -f "$CONFIG_FILE" ]; then
        local ssh_keys
        ssh_keys=$(grep -E "^ssh_authorized_keys:" -A 100 "$CONFIG_FILE" 2>/dev/null | grep -E "^\s+-" | sed 's/^\s*-\s*//')
        
        if [ -n "$ssh_keys" ]; then
            local admin_user
            admin_user=$(grep -E "^admin_user:" "$CONFIG_FILE" | awk '{print $2}')
            admin_user="${admin_user:-cx}"
            
            local ssh_dir="/home/${admin_user}/.ssh"
            mkdir -p "$ssh_dir"
            echo "$ssh_keys" >> "${ssh_dir}/authorized_keys"
            chmod 700 "$ssh_dir"
            chmod 600 "${ssh_dir}/authorized_keys"
            chown -R "${admin_user}:${admin_user}" "$ssh_dir"
            
            log "SSH keys installed for user: $admin_user"
            
            # Disable password auth if keys provided
            sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config.d/cx.conf
            systemctl reload ssh
            log "Password authentication disabled (SSH keys configured)"
        fi
    fi
    
    log "SSH configured and running"
    state_done "ssh"
}

provision_admin_user() {
    if state_check "admin_user"; then
        log "Admin user already configured, skipping"
        return 0
    fi
    
    log_section "Configuring Admin User"
    
    local admin_user="${CX_ADMIN_USER:-cx}"
    
    if [ -f "$CONFIG_FILE" ]; then
        local cfg_user
        cfg_user=$(grep -E "^admin_user:" "$CONFIG_FILE" 2>/dev/null | awk '{print $2}')
        [ -n "$cfg_user" ] && admin_user="$cfg_user"
    fi
    
    # Create user if doesn't exist
    if ! id "$admin_user" &>/dev/null; then
        useradd -m -s /bin/bash -G sudo,docker "$admin_user"
        log "Created admin user: $admin_user"
    fi
    
    # Ensure sudo access
    echo "${admin_user} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${admin_user}"
    chmod 440 "/etc/sudoers.d/${admin_user}"
    
    log "Admin user configured: $admin_user"
    state_done "admin_user"
}

provision_apt_repos() {
    if state_check "apt_repos"; then
        log "APT repositories already configured, skipping"
        return 0
    fi

    log_section "Configuring APT Repositories"

    # Enable Ubuntu updates and backports
    add-apt-repository -y universe
    add-apt-repository -y multiverse

    # Update package lists
    apt-get update || log "WARNING: apt-get update failed (offline mode?)"

    # Configure automatic updates for security patches
    if [ ! -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
        echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
        echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
        log "Automatic security updates configured"
    fi

    log "APT repositories configured"
    state_done "apt_repos"
}

provision_cx() {
    if state_check "cx"; then
        log "CX already installed, skipping"
        return 0
    fi
    
    log_section "Installing CX"
    
    # Check if we have network for installation
    if ping -c 1 -W 5 repo.cxlinux.ai &>/dev/null; then
        apt-get install -y cx-core || log "WARNING: cx-core installation failed"
    else
        log "No network access to CX repository"
        log "CX will be installed from local packages if available"
        
        # Check for local packages
        if ls /var/cache/cx/*.deb &>/dev/null; then
            dpkg -i /var/cache/cx/*.deb || true
            apt-get install -f -y
        fi
    fi
    
    state_done "cx"
}

provision_security() {
    if state_check "security"; then
        log "Security baseline already applied, skipping"
        return 0
    fi
    
    log_section "Applying Security Baseline"
    
    # Apply sysctl settings
    sysctl --system
    
    # Enable AppArmor
    if command -v aa-status &>/dev/null; then
        systemctl enable apparmor
        systemctl start apparmor
        log "AppArmor enabled"
    fi
    
    # Configure firewall (nftables)
    if command -v nft &>/dev/null; then
        cat > /etc/nftables.conf << 'EOF'
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        
        # Allow established connections
        ct state established,related accept
        
        # Allow loopback
        iif lo accept
        
        # Allow SSH
        tcp dport 22 accept
        
        # Allow CX web console (when enabled)
        tcp dport 8006 accept
        
        # Allow ICMP
        icmp type echo-request accept
        icmpv6 type echo-request accept
        
        # Drop invalid
        ct state invalid drop
    }
    
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF
        systemctl enable nftables
        systemctl start nftables
        log "Firewall configured (nftables)"
    fi
    
    log "Security baseline applied"
    state_done "security"
}

provision_webconsole() {
    if state_check "webconsole"; then
        log "Web console already configured, skipping"
        return 0
    fi
    
    log_section "Configuring Web Console"
    
    # Web console will be configured when cx-console is installed
    # This step prepares the environment
    
    mkdir -p /etc/cx/console
    mkdir -p /var/lib/cx/console
    
    log "Web console environment prepared"
    log "Install cx-console to enable web management on port 8006"
    
    state_done "webconsole"
}

provision_gpu_drivers() {
    if state_check "gpu_drivers"; then
        log "GPU drivers already configured, skipping"
        return 0
    fi

    log_section "Configuring GPU Drivers (Ubuntu 24.04)"

    # Detect GPU hardware
    local nvidia_gpu=$(lspci | grep -i nvidia | wc -l)
    local amd_gpu=$(lspci | grep -i 'vga.*amd\|vga.*ati' | wc -l)

    if [ "$nvidia_gpu" -gt 0 ]; then
        log "NVIDIA GPU detected, installing drivers..."
        # Use ubuntu-drivers for automatic driver selection
        ubuntu-drivers autoinstall || log "WARNING: NVIDIA driver installation failed"
        log "NVIDIA drivers installed (reboot required)"
    fi

    if [ "$amd_gpu" -gt 0 ]; then
        log "AMD GPU detected, installing drivers..."
        apt-get install -y mesa-vulkan-drivers xserver-xorg-video-amdgpu
        log "AMD drivers installed"
    fi

    # Install common GPU monitoring tools
    apt-get install -y \
        mesa-utils \
        vulkan-tools \
        vainfo \
        vdpauinfo || log "WARNING: GPU tools installation failed"

    state_done "gpu_drivers"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    log_section "CX Linux First Boot Provisioning v${PROVISION_VERSION} (Ubuntu 24.04)"
    log "Started: $(date)"

    # Create log directory
    mkdir -p "$(dirname "$PROVISION_LOG")"

    # Run provisioning steps in order
    provision_hostname
    provision_network
    provision_timezone
    provision_ssh
    provision_admin_user
    provision_apt_repos
    provision_cx
    provision_security
    provision_gpu_drivers
    provision_webconsole
    
    # Mark provisioning complete
    state_set "provision_version" "$PROVISION_VERSION"
    state_set "provision_complete" "$(date -Iseconds)"
    
    log_section "Provisioning Complete"
    log "Finished: $(date)"
    log ""
    log "System is ready. Connect via SSH or web console (port 8006)"
    log ""
}

# Run main function
main "$@"
