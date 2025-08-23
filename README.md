# MLOps Homelab GitOps Repository

## Overview
Production-grade MLOps platform on K3s using GitOps principles with ArgoCD.
Prepared for Kubeflow installation with reserved resources.

### Stack Components
- **Infrastructure**: Longhorn (storage), MetalLB (networking), Traefik (ingress)
- **Data Layer**: PostgreSQL, Redis, MinIO, Docker Registry
- **ML Platform**: MLflow, JupyterHub, LocalStack (Kubeflow-ready)
- **Monitoring**: Prometheus, Grafana, Loki

## Resource Allocation (40GB RAM Total)
- **Infrastructure**: ~3GB
- **Data Services**: ~6GB
- **ML Platform (without Kubeflow)**: ~8GB
- **Monitoring**: ~3GB
- **Reserved for Kubeflow**: ~15GB
- **System/Buffer**: ~5GB

## MetalLB IP Allocation (192.168.1.240-259)
- 240: Traefik Ingress Controller
- 241: MinIO S3 API
- 242: MLflow Direct Access
- 243-259: Reserved for Kubeflow services

## Quick Start

```bash
cd bootstrap
./00-prerequisites.sh
./01-k3s-install.sh
./02-argocd-bootstrap.sh
```

## Default Credentials
- ArgoCD: admin / (check with kubectl)
- Grafana: admin / admin123
- MinIO: minio / minio123
- PostgreSQL: postgres / postgrespw
- JupyterHub: any-username / jupyter123
