#!/bin/bash
set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

BACKUP_DIR="backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

log "Starting backup to $BACKUP_DIR..."

# Backup namespaces
for ns in data mlflow jupyter monitoring kubeflow; do
    if kubectl get namespace $ns &>/dev/null; then
        log "Backing up namespace: $ns"
        kubectl get all,pvc,configmap,secret -n $ns -o yaml > $BACKUP_DIR/$ns.yaml
    fi
done

# Backup Longhorn volumes
log "Backing up Longhorn volume list..."
kubectl get volumes.longhorn.io -n longhorn-system -o yaml > $BACKUP_DIR/longhorn-volumes.yaml

# Backup ArgoCD applications
log "Backing up ArgoCD applications..."
kubectl get applications -n argocd -o yaml > $BACKUP_DIR/argocd-apps.yaml

log "✓ Backup completed: $BACKUP_DIR"
