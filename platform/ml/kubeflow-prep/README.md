# Kubeflow Installation Guide

## Resources Reserved
- **CPU**: 6 cores
- **Memory**: 15GB
- **Storage**: 200GB
- **IPs**: 192.168.1.243-259

## Pre-Installation Checklist
- [ ] Base platform running (PostgreSQL, MinIO, etc.)
- [ ] At least 15GB RAM available
- [ ] MetalLB IP range configured
- [ ] Longhorn storage working

## Installation Steps

1. **Verify resources**:
```bash
kubectl top nodes
kubectl get pvc --all-namespaces
```

2. **Run installation script**:
```bash
cd scripts
./install-kubeflow.sh
```

3. **Monitor installation**:
```bash
kubectl get pods -n kubeflow -w
```

## Service URLs After Installation
- Central Dashboard: http://192.168.1.243
- Pipelines UI: http://192.168.1.244
- KServe: http://192.168.1.245
- Katib UI: http://192.168.1.246
- Notebooks: http://192.168.1.247

## Integration Points
- **MinIO**: minio.data.svc.cluster.local:9000
- **PostgreSQL**: postgresql.data.svc.cluster.local:5432
- **MLflow**: mlflow.mlflow.svc.cluster.local:5000
- **Docker Registry**: docker-registry.data.svc.cluster.local:5000

## Default Credentials
- Username: user@example.com
- Password: 12341234

## Troubleshooting

### If pods are pending:
```bash
kubectl describe pod <pod-name> -n kubeflow
kubectl get events -n kubeflow --sort-by='.lastTimestamp'
```

### If out of resources:
```bash
# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces | sort -k4 -h

# Scale down non-critical services
kubectl scale deployment --replicas=0 <deployment> -n <namespace>
```

### Reset Kubeflow:
```bash
kubectl delete namespace kubeflow istio-system knative-serving knative-eventing
```
