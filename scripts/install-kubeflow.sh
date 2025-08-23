#!/bin/bash
set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Preparing for Kubeflow installation..."

# Clone Kubeflow manifests
if [ ! -d "kubeflow-manifests" ]; then
    log "Cloning Kubeflow manifests..."
    git clone https://github.com/kubeflow/manifests.git kubeflow-manifests
fi

cd kubeflow-manifests

# Create custom overlay for existing services
mkdir -p custom-overlay
cat > custom-overlay/kustomization.yaml << 'KUSTOMIZE'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../example

configMapGenerator:
- name: pipeline-install-config
  namespace: kubeflow
  behavior: merge
  literals:
  - bucketName=kubeflow-pipelines
  - minioServiceHost=minio.data.svc.cluster.local
  - minioServicePort=9000
KUSTOMIZE

# Install Kubeflow
log "Installing Kubeflow components..."
while ! kustomize build custom-overlay | kubectl apply -f -; do
    log "Retrying Kubeflow installation..."
    sleep 10
done

# Wait for deployments
log "Waiting for Kubeflow deployments..."
kubectl wait --for=condition=available --timeout=600s deployment --all -n kubeflow || true

# Configure LoadBalancer IPs
log "Configuring Kubeflow service IPs..."
kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"loadBalancerIP":"192.168.1.243"}}' || true

log "✓ Kubeflow installation completed"
log ""
log "Access Kubeflow at:"
log "  Central Dashboard: http://192.168.1.243"
log ""
log "Default credentials:"
log "  Username: user@example.com"
log "  Password: 12341234"
