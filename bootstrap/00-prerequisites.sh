#!/bin/bash
set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Installing system prerequisites..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y \
    curl wget git jq bc \
    open-iscsi nfs-common \
    software-properties-common \
    python3-pip

# Install Python packages
pip3 install --user pyyaml yamllint

# Configure kernel parameters
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

# Start iscsid for Longhorn
sudo systemctl enable --now iscsid

# Create directories
sudo mkdir -p /var/lib/longhorn
sudo chmod 755 /var/lib/longhorn

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

log "✓ Prerequisites installed"
