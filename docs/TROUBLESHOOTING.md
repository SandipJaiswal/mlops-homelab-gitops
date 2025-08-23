# Troubleshooting Guide

## Common Issues and Solutions

### 1. Pods Stuck in Pending State

**Symptoms**: Pods remain in Pending status
**Cause**: Resource constraints or storage issues

**Solution**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes

# Check PVC status
kubectl get pvc --all-namespaces
```

### 2. ArgoCD Sync Failures

**Symptoms**: Applications show as OutOfSync or Failed
**Cause**: Invalid manifests or resource conflicts

**Solution**:
```bash
# Check application status
kubectl get applications -n argocd

# Get detailed error
kubectl describe application <app-name> -n argocd

# Force sync
argocd app sync <app-name> --force

# Or via kubectl
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

### 3. Storage Issues with Longhorn

**Symptoms**: PVCs not binding, storage errors
**Cause**: Longhorn node configuration issues

**Solution**:
```bash
# Check Longhorn status
kubectl get nodes.longhorn.io -n longhorn-system

# Check disk status
kubectl describe nodes.longhorn.io t495 -n longhorn-system

# Restart Longhorn manager
kubectl rollout restart daemonset/longhorn-manager -n longhorn-system

# Check Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
```

### 4. MetalLB IP Allocation Issues

**Symptoms**: Services stuck in Pending for LoadBalancer
**Cause**: IP pool exhausted or conflicts

**Solution**:
```bash
# Check IP pool
kubectl get ipaddresspool -n metallb-system -o yaml

# Check allocated IPs
kubectl get svc --all-namespaces | grep LoadBalancer

# Check MetalLB logs
kubectl logs -n metallb-system deployment/controller

# Restart MetalLB
kubectl rollout restart deployment/controller -n metallb-system
```

### 5. Out of Memory Errors

**Symptoms**: OOMKilled pods, system slowness
**Cause**: Insufficient resources for workloads

**Solution**:
```bash
# Check memory usage
kubectl top nodes
kubectl top pods --all-namespaces | sort -k4 -h

# Scale down non-critical services
kubectl scale deployment <deployment> --replicas=0 -n <namespace>

# Adjust resource limits in values files
# Then sync via ArgoCD
```

### 6. Service Not Accessible

**Symptoms**: Cannot reach service via browser
**Cause**: Ingress misconfiguration or DNS issues

**Solution**:
```bash
# Check ingress
kubectl get ingress --all-namespaces

# Check service endpoints
kubectl get endpoints -n <namespace>

# Test service internally
kubectl run test-pod --image=busybox --rm -it -- wget -O- http://<service>.<namespace>.svc.cluster.local

# Check /etc/hosts entries
cat /etc/hosts | grep local
```

## Performance Tuning

### For 40GB RAM Optimization

1. **Monitor continuously**:
```bash
watch -n 5 'kubectl top nodes; echo "---"; kubectl top pods --all-namespaces | head -20'
```

2. **Adjust replica counts**:
```bash
# Single node doesn't need multiple replicas
kubectl scale deployment --all --replicas=1 -n <namespace>
```

3. **Clear unused images**:
```bash
sudo k3s crictl rmi --prune
```

4. **Check disk usage**:
```bash
df -h
du -sh /var/lib/longhorn/*
```

## Recovery Procedures

### Full Cluster Recovery
```bash
# 1. Restore from backup
./scripts/restore.sh backups/<timestamp>

# 2. Reapply GitOps
kubectl apply -f argocd/root-app.yaml

# 3. Wait for sync
watch kubectl get applications -n argocd
```

### Reset Specific Service
```bash
# Delete and recreate via ArgoCD
kubectl delete application <app-name> -n argocd
kubectl apply -f argocd/app-sets/<category>.yaml
```

## Logs Collection

```bash
# Collect all logs for debugging
mkdir -p debug-logs
for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  kubectl logs --all-containers=true --namespace=$ns --tail=100 > debug-logs/$ns.log 2>&1
done

# Check K3s logs
journalctl -u k3s -n 1000 > debug-logs/k3s.log
```
