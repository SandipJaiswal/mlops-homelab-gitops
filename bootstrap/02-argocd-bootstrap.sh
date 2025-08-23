#!/bin/bash
set -euo pipefail

# -------------------------
# 02-argocd-bootstrap.sh
# Bootstraps ArgoCD itself and the GitOps “root” application.
# Must be executed **after** 01-k3s-install.sh
# -------------------------

REPO_URL="https://github.com/SandipJaiswal/mlops-homelab-gitops"
ARGOCD_VERSION="v2.11.0"
ARGOCD_NAMESPACE="argocd"
ROOT_APP_FILE="../argocd/root-app.yaml"

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
# 1.  Create argocd namespace
# ----------------------------------------------------------
log "Creating namespace: ${ARGOCD_NAMESPACE}"
kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# ----------------------------------------------------------
# 2.  Install ArgoCD
# ----------------------------------------------------------
log "Installing ArgoCD ${ARGOCD_VERSION} ..."
if ! kubectl get deploy argocd-server -n "${ARGOCD_NAMESPACE}" >/dev/null 2>&1; then
  kubectl apply -n "${ARGOCD_NAMESPACE}" \
    -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
else
  log "ArgoCD already installed – skipping"
fi

log "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available \
  --timeout=600s deployment/argocd-server -n "${ARGOCD_NAMESPACE}"

# ----------------------------------------------------------
# 3.  Patch server to allow insecure (no TLS) for quick-start
#     Remove if you expose via HTTPS.
# ----------------------------------------------------------
kubectl patch deployment argocd-server -n "${ARGOCD_NAMESPACE}" \
  --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'

# ----------------------------------------------------------
# 4.  Deploy the GitOps “root” application
# ----------------------------------------------------------
log "Creating root application that bootstraps everything else..."
kubectl apply -f "${ROOT_APP_FILE}"

# ----------------------------------------------------------
# 5.  Display access information
# ----------------------------------------------------------
log "Retrieving ArgoCD admin password..."
ARGO_PWD=$(kubectl -n "${ARGOCD_NAMESPACE}" \
  get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

log "--------------------------------------------------"
log "ArgoCD bootstrap complete!"
log "  URL: http://localhost:8080  (kubectl port-forward)"
log "  User: admin"
log "  Password: ${ARGO_PWD}"
log "--------------------------------------------------"
log "Next: run 03-configure-infra.sh to deploy infra stack"
