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

# Wait for ArgoCD server
log "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Apply root app if it exists
if [ -f "argocd/root-app.yaml" ]; then
    log "Applying root application..."
    kubectl apply -f argocd/root-app.yaml
else
    log "⚠ Root application file not found at argocd/root-app.yaml"
    log "Creating minimal root application..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: main
    path: argocd/app-sets
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
fi

# Get password
log "Retrieving ArgoCD admin password..."
sleep 10  # Give time for secret to be created

if kubectl get secret argocd-initial-admin-secret -n argocd &>/dev/null; then
    PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    log "ArgoCD Admin Username: admin"
    log "ArgoCD Admin Password: $PASSWORD"
    
    # Save password to file
    echo "$PASSWORD" > argocd-admin-password.txt
    chmod 600 argocd-admin-password.txt
    log "Password saved to: argocd-admin-password.txt"
else
    log "⚠ Admin secret not found yet. It may take a few minutes to create."
    log "Run this later to get password:"
    echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
fi

log "✓ ArgoCD bootstrap completed"
log ""
log "Access ArgoCD UI with:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "URL: https://localhost:8080"
echo "Username: admin"
echo "Password: $(cat argocd-admin-password.txt 2>/dev/null || echo 'run the password command above')"
