#!/bin/bash
# ArgoCD installation and root app deployment
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/SandipJaiswal/mlops-homelab-gitops}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

install_argocd() {
    log "Installing ArgoCD..."
    
    # Create namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
    
    log "✓ ArgoCD installed"
}

deploy_app_of_apps() {
    log "Deploying App-of-Apps..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: homelab-app-of-apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: main
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
EOF

    log "✓ App-of-Apps deployed"
}

get_argocd_password() {
    log "Retrieving ArgoCD admin password..."
    
    timeout 60 bash -c 'until kubectl get secret argocd-initial-admin-secret -n argocd &> /dev/null; do sleep 2; done'
    PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    log "ArgoCD Access Information:"
    log "URL: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    log "Username: admin"
    log "Password: $PASSWORD"
}

main() {
    log "Starting ArgoCD bootstrap..."
    
    install_argocd
    deploy_app_of_apps
    get_argocd_password
    
    log "✓ ArgoCD bootstrap completed"
    log "Configure REPO_URL environment variable and sync applications in ArgoCD UI"
}

main "$@"
