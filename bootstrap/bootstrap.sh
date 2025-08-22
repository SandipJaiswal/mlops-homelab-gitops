#!/bin/bash
# Master GitOps bootstrap script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="${REPO_URL:-https://github.com/SandipJaiswal/mlops-homelab-gitops}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

main() {
    log "Starting GitOps MLOps Homelab Bootstrap"
    
    # Phase 1: System prerequisites
    log "Phase 1: System Preparation"
    "$SCRIPT_DIR/01-system-prep.sh"
    
    # Phase 2: K3s installation
    log "Phase 2: K3s Installation"
    "$SCRIPT_DIR/02-k3s-install.sh"
    
    # Phase 3: ArgoCD and App-of-Apps
    log "Phase 3: ArgoCD Bootstrap"
    REPO_URL="$REPO_URL" "$SCRIPT_DIR/03-argocd-bootstrap.sh"
    
    log "✓ GitOps bootstrap completed!"
    log ""
    log "Next steps:"
    log "1. Update REPO_URL in apps/app-of-apps.yaml to point to your repository"
    log "2. Configure MetalLB IP range in clusters/homelab/values/metallb-values.yaml"
    log "3. Access ArgoCD UI and sync applications:"
    log "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
    log "4. Monitor application sync status in ArgoCD"
    log ""
    log "All infrastructure is now managed declaratively through GitOps!"
}

main "$@"
