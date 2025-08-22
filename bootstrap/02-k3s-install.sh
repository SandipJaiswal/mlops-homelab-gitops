#!/bin/bash
# K3s installation with proper configuration
set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

main() {
    log "Installing K3s..."
    
    # Check if already installed
    if command -v k3s &> /dev/null && sudo systemctl is-active --quiet k3s; then
        log "✓ K3s already installed and running"
        return 0
    fi
    
    # Install K3s with optimized configuration
    curl -sfL https://get.k3s.io | sh -s - \
        --disable local-storage \
        --disable metrics-server \
        --flannel-backend=host-gw \
        --kube-controller-manager-arg=bind-address=0.0.0.0 \
        --kube-proxy-arg=metrics-bind-address=0.0.0.0 \
        --kube-scheduler-arg=bind-address=0.0.0.0 \
        --write-kubeconfig-mode=644
    
    # Setup kubeconfig for user
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $(id -u):$(id -g) ~/.kube/config
    
    # Wait for node to be ready
    timeout 300 bash -c 'until kubectl get nodes | grep -q Ready; do sleep 5; done'
    
    log "✓ K3s installation completed"
    kubectl get nodes
}

main "$@"
