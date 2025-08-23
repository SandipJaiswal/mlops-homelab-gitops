# Quick Start Guide

## Prerequisites
- Ubuntu with 40GB RAM
- Internet connection
- Git installed

## Step 1: System Preparation
```bash
cd bootstrap
./00-prerequisites.sh
```

## Step 2: Install K3s
```bash
./01-k3s-install.sh
```

## Step 3: Bootstrap ArgoCD
```bash
./02-argocd-bootstrap.sh
```

## Step 4: Update /etc/hosts
Add these entries:
```
192.168.1.240 traefik.local grafana.local mlflow.local jupyter.local localstack.local prometheus.local longhorn.local
192.168.1.241 minio.local minio-console.local
192.168.1.242 mlflow-direct.local
```

## Step 5: Access Services

### ArgoCD
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Access: https://localhost:8080

### Other Services
- Grafana: http://grafana.local
- MLflow: http://mlflow.local
- MinIO Console: http://minio.local
- JupyterHub: http://jupyter.local
- Prometheus: http://prometheus.local
- Longhorn: http://longhorn.local

## Step 6: Health Check
```bash
cd ../scripts
./health-check.sh
```

## Step 7: Install Kubeflow (Optional)
```bash
./install-kubeflow.sh
```

## Default Credentials
| Service | Username | Password |
|---------|----------|----------|
| ArgoCD | admin | (kubectl command) |
| Grafana | admin | admin123 |
| MinIO | minio | minio123 |
| PostgreSQL | postgres | postgrespw |
| JupyterHub | any | jupyter123 |
