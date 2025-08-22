#!/bin/bash
# Minimal system preparation - prerequisites only
set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

main() {
    log "Starting system preparation..."
    
    # Update system
    sudo apt update && sudo apt upgrade -y
    
    # Install required packages
    sudo apt install -y curl wget git jq bc open-iscsi
    
    # Configure system settings for K3s
    echo 'fs.inotify.max_user_watches=1048576' | sudo tee -a /etc/sysctl.conf
    echo 'fs.inotify.max_user_instances=1024' | sudo tee -a /etc/sysctl.conf
    echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    
    # Start open-iscsi for Longhorn
    sudo systemctl enable iscsid
    sudo systemctl start iscsid
    
    # Create Longhorn directory
    sudo mkdir -p /var/lib/longhorn
    sudo chown -R root:root /var/lib/longhorn
    
    log "✓ System preparation completed"
}

main "$@"
