#!/bin/bash
set -euo pipefail

# -------------------------
# 04-configure-data-services.sh
# Deploys data services (PostgreSQL, Redis, MinIO, Docker Registry) using ArgoCD.
# Must be executed **after** 03-configure-infra.sh
# -------------------------

# colours
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[$(date '+%F %T')]${NC} $1"; }
fail() { echo -e "${RED}[ERROR]${NC} $1" >&2 ; exit 1; }

# ----------------------------------------------------------
# 0.  Pre-flight
# ----------------------------------------------------------
command -v kubectl >/dev/null 2>&1 || fail "kubectl not found"
kubectl cluster-info >/dev/null            || fail "Cluster unreachable"

# ----------------------------------------------------------
# 1.  Deploy Data Services ApplicationSet
# ----------------------------------------------------------
log "Deploying data services ApplicationSet..."
kubectl apply -f ../argocd/app-sets/data-services.yaml

log "Waiting for data services components to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

log "Data services deployment initiated. Check ArgoCD UI for status."

# ----------------------------------------------------------
# 2.  Display Next Steps
# ----------------------------------------------------------
log "--------------------------------------------------"
log "Data services deployment initiated."
log "Check ArgoCD UI for the status of the following components:"
log "  - PostgreSQL"
log "  - Redis"
log "  - MinIO"
log "  - Docker Registry"
log "--------------------------------------------------"
log "Next: run 05-configure-ml-platform.sh to deploy ML platform"
