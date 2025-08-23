#!/bin/bash
set -euo pipefail

# --- Constants ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Functions ---
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_sudo() {
    if ! sudo -v; then
        error "This script needs to be run with sudo privileges."
    fi
}

install_system_packages() {
    log "Updating system packages..."
    sudo apt update && sudo apt upgrade -y

    log "Installing required system packages..."
    sudo apt install -y \
        curl wget git jq bc \
        open-iscsi nfs-common \
        software-properties-common \
        python3-pip
}

configure_kernel_parameters() {
    log "Configuring kernel parameters..."
    cat << SYSCTL | sudo tee /etc/sysctl.d/90-k3s.conf
fs.inotify.max_user_watches=1048576
fs.inotify.max_user_instances=8192
vm.max_map_count=524288
vm.swappiness=10
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
SYSCTL

    sudo sysctl --system
}

setup_directories() {
    log "Setting up directories..."
    sudo mkdir -p /var/lib/longhorn
    sudo chmod 755 /var/lib/longhorn
}

disable_swap() {
    log "Disabling swap..."
    sudo swapoff -a
    sudo sed -i '/ swap / s/^/#/' /etc/fstab
}

main() {
    check_sudo
    install_system_packages
    configure_kernel_parameters
    setup_directories
    disable_swap
    log "✓ Prerequisites installed successfully"
}

# --- Main ---
main
