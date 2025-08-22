#!/bin/bash
# ArgoCD installation and root app deployment
set -euo pipefail

REPO_URL="https://github.com/SandipJaiswal/mlops-homelab-gitops"

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
    path: apps/app-of-apps.yaml
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

create_longhorn_node_config() {
    log "Creating Longhorn node disk configuration..."
    
    # Wait for Longhorn namespace to exist
    timeout 300 bash -c 'until kubectl get namespace longhorn-system &> /dev/null; do sleep 5; done'
    
    # Wait for Longhorn manager to be ready
    timeout 600 bash -c 'until kubectl get pods -n longhorn-system | grep longhorn-manager | grep -q Running; do sleep 10; done'
    
    # Wait for node to be detected by Longhorn
    timeout 300 bash -c 'until kubectl get nodes.longhorn.io t495 -n longhorn-system &> /dev/null; do sleep 10; done'
    
    # Configure disk on the node
    log "Applying disk configuration to node t495..."
    kubectl patch nodes.longhorn.io t495 -n longhorn-system --type='merge' -p='{
      "spec": {
        "disks": {
          "default-disk": {
            "allowScheduling": true,
            "evictionRequested": false,
            "path": "/var/lib/longhorn",
            "storageReserved": 21474836480,
            "tags": []
          }
        }
      }
    }'
    
    # Restart longhorn manager to pick up disk configuration
    log "Restarting Longhorn manager..."
    kubectl rollout restart daemonset/longhorn-manager -n longhorn-system
    kubectl wait --for=condition=ready pod -l app=longhorn-manager -n longhorn-system --timeout=300s
    
    # Wait for disk detection
    sleep 60
    
    log "✓ Longhorn node disk configuration completed"
}

get_argocd_password() {
    log "Retrieving ArgoCD admin password..."
    
    timeout 60 bash -c 'until kubectl get secret argocd-initial-admin-secret -n argocd &> /dev/null; do sleep 2; done'
    PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    log "ArgoCD Access Information:"
    log "URL: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    log "Username: admin"
    log "Password: $PASSWORD"
    
    # Save password to file for later use
    echo "$PASSWORD" > ~/.argocd-password
    chmod 600 ~/.argocd-password
}

verify_deployment() {
    log "Verifying deployment status..."
    
    # Check ArgoCD applications
    timeout 300 bash -c 'until kubectl get applications -n argocd | grep -q homelab; do sleep 10; done'
    
    log "ArgoCD Applications:"
    kubectl get applications -n argocd
    
    log "Cluster nodes:"
    kubectl get nodes
    
    log "✓ Deployment verification completed"
}

main() {
    log "Starting ArgoCD bootstrap..."
    
    install_argocd
    deploy_app_of_apps
    
    # Wait a bit for ArgoCD to start syncing
    log "Waiting for initial ArgoCD sync to begin..."
    sleep 30
    
    # Configure Longhorn after it's deployed
    create_longhorn_node_config
    
    get_argocd_password
    verify_deployment
    
    log "✓ ArgoCD bootstrap completed successfully"
    log ""
    log "Next steps:"
    log "1. Access ArgoCD UI and monitor application sync"
    log "2. All applications will be deployed automatically via GitOps"
    log "3. Check application status: kubectl get applications -n argocd"
    log "4. Monitor pod status: kubectl get pods --all-namespaces"
}

main "$@"
