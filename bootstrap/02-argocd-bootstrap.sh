#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/SandipJaiswal/mlops-homelab-gitops"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Bootstrapping ArgoCD..."

# Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.11.0/manifests/install.yaml

# Wait for ArgoCD
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Apply root app
kubectl apply -f ../argocd/root-app.yaml

# Get password
log "Admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

log "✓ ArgoCD bootstrap completed"
