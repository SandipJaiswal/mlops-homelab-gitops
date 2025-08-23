#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[CHECK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check K3s
if kubectl get nodes &>/dev/null; then
    log "✓ K3s is running"
    kubectl get nodes
else
    error "✗ K3s is not accessible"
    exit 1
fi

# Check ArgoCD
if kubectl get deploy argocd-server -n argocd &>/dev/null; then
    log "✓ ArgoCD is deployed"
else
    warn "⚠ ArgoCD is not deployed"
fi

# Check Longhorn
if kubectl get storageclass longhorn &>/dev/null; then
    log "✓ Longhorn storage is available"
else
    error "✗ Longhorn storage is not available"
fi

# Check MetalLB
if kubectl get ipaddresspool -n metallb-system &>/dev/null; then
    log "✓ MetalLB is configured"
else
    warn "⚠ MetalLB is not configured"
fi

# Check services
SERVICES=(
    "postgresql:data"
    "redis-master:data"
    "minio:data"
    "mlflow:mlflow"
    "traefik:traefik"
)

for svc in "${SERVICES[@]}"; do
    IFS=':' read -r name namespace <<< "$svc"
    if kubectl get svc $name -n $namespace &>/dev/null; then
        log "✓ Service $name in namespace $namespace is running"
    else
        warn "⚠ Service $name in namespace $namespace not found"
    fi
done

# Check resource usage
log "Resource Usage:"
kubectl top nodes 2>/dev/null || warn "Metrics server not available"

# Check PVCs
log "Persistent Volume Claims:"
kubectl get pvc --all-namespaces

log "Health check completed!"
