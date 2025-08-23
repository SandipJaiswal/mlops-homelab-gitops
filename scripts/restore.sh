#!/bin/bash
set -euo pipefail

BACKUP_DIR=$1

if [ -z "$BACKUP_DIR" ]; then
    echo "Usage: $0 <backup-directory>"
    exit 1
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting restore from: $BACKUP_DIR"

# Restore namespaces
for file in $BACKUP_DIR/*.yaml; do
    log "Restoring: $file"
    kubectl apply -f $file || true
done

log "✓ Restore completed"
