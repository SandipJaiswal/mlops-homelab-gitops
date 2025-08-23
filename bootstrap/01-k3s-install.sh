#!/bin/bash
set -euo pipefail

# --- Constants ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# --- Configuration ---
NODE_NAME="t495"

# --- Functions ---
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

install_k3s() {
    log "Installing K3s..."
    if command -v k3s &> /dev/null; then
        log "K3s is already installed. Skipping installation."
        k3s --version
        return
    fi

    curl -sfL https://get.k3s.io | sh -s - \
        --node-name="${NODE_NAME}" \
        --disable local-storage \
        --disable metrics-server \
        --flannel-backend=host-gw \
        --kube-controller-manager-arg=bind-address=0.0.0.0 \
        --kube-proxy-arg=metrics-bind-address=0.0.0.0 \
        --kube-scheduler-arg=bind-address=0.0.0.0 \
        --kubelet-arg=max-pods=250 \
        --kubelet-arg=eviction-hard="memory.available<1Gi" \
        --write-kubeconfig-mode=644
}

configure_kubectl() {
    log "Configuring kubectl..."
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $(id -u):$(id -g) ~/.kube/config
}

label_node() {
    log "Labeling node..."
    kubectl label node "${NODE_NAME}" node-role.kubernetes.io/worker=true --overwrite
}

wait_for_node_ready() {
    log "Waiting for node to be ready..."
    kubectl wait --for=condition=Ready node/"${NODE_NAME}" --timeout=300s
}

main() {
    install_k3s
    configure_kubectl
    wait_for_node_ready
    label_node
    log "✓ K3s installation and configuration completed successfully"
}

# --- Main ---
main
