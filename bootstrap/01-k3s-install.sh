#!/bin/bash
set -euo pipefail

NODE_NAME="t495"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Installing K3s with resource optimization..."

if command -v k3s &> /dev/null; then
    log "K3s is already installed"
    k3s --version
else
    curl -sfL https://get.k3s.io | sh -s - \
        --node-name=${NODE_NAME} \
        --disable local-storage \
        --disable metrics-server \
        --flannel-backend=host-gw \
        --kube-controller-manager-arg=bind-address=0.0.0.0 \
        --kube-proxy-arg=metrics-bind-address=0.0.0.0 \
        --kube-scheduler-arg=bind-address=0.0.0.0 \
        --kubelet-arg=max-pods=250 \
        --kubelet-arg=eviction-hard="memory.available<2Gi" \
        --kubelet-arg=system-reserved="cpu=500m,memory=1Gi" \
        --kubelet-arg=kube-reserved="cpu=500m,memory=1Gi" \
        --write-kubeconfig-mode=644
fi

# Setup kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Wait for node
kubectl wait --for=condition=Ready node/${NODE_NAME} --timeout=300s

# Label node
kubectl label node ${NODE_NAME} node-role.kubernetes.io/worker=true --overwrite
kubectl label node ${NODE_NAME} kubernetes.io/hostname=${NODE_NAME} --overwrite

log "✓ K3s installed and configured"
