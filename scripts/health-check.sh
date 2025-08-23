#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[CHECK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check system
kubectl get nodes -o wide
kubectl get applications -n argocd -o wide || warn "ArgoCD apps not found"

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
        log "✓ Service $name in namespace $namespace"
    else
        warn "⚠ Service $name in namespace $namespace not found"
    fi
done

# Check storage
kubectl get pvc --all-namespaces
