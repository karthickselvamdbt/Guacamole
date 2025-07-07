# Guacamole Deployment Guide for Ubuntu Kubernetes Cluster (10.0.7.161)

## Quick Start for Your Setup

### Step 1: Configure kubectl Connection
```powershell
# Run this to configure kubectl for your cluster
.\setup-cluster.ps1
```

### Step 2: Test Cluster Connectivity
```powershell
# Verify your cluster is ready
.\test-cluster.ps1
```

### Step 3: Deploy Guacamole
```powershell
# Deploy all components
.\deploy.ps1
```

## What's Pre-configured for Your Setup

1. **Ingress Domain**: Set to `guacamole.10.0.7.161.nip.io` (uses nip.io for easy local access)
2. **Storage Class**: Set to `local-path` (common for single-node clusters)
3. **Load Balancer**: Configured for direct IP access

## Access Your Guacamole Installation

After deployment, you can access Guacamole at:
- **URL**: http://guacamole.10.0.7.161.nip.io (if ingress is working)
- **Direct IP**: Check the LoadBalancer external IP with `kubectl get svc -n guacamole`

### Default Credentials
- **Username**: `guacadmin`
- **Password**: `guacadmin123`

**🔐 Security Note**: For production, generate secure passwords:
```powershell
.\generate-secrets.ps1
```

## Troubleshooting Your Setup

### If kubectl connection fails:
```powershell
# Manual kubectl configuration
kubectl config set-cluster ubuntu-cluster --server=https://10.0.7.161:6443 --insecure-skip-tls-verify=true
kubectl config set-credentials kubernetes --username=kubernetes --password=root
kubectl config set-context ubuntu-context --cluster=ubuntu-cluster --user=kubernetes
kubectl config use-context ubuntu-context
```

### If storage class doesn't exist:
```powershell
# Check available storage classes
kubectl get storageclass

# If none exist, you might need to install one:
# For single-node clusters, rancher's local-path-provisioner is common:
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

### If ingress doesn't work:
```powershell
# Check if you have an ingress controller
kubectl get pods -A | findstr ingress

# If no ingress controller, you can access via LoadBalancer IP:
kubectl get svc guacamole-service -n guacamole
```

## Common Issues and Solutions

1. **Storage Issues**: If PVCs stay pending, check your storage class with `kubectl get storageclass`
2. **Network Issues**: If pods can't communicate, check if network policies are supported
3. **Resource Issues**: If pods are pending, check node resources with `kubectl describe nodes`

## Security Considerations for Your Setup

Since you're using basic auth and potentially no TLS:
1. **Change default passwords immediately**
2. **Consider setting up proper TLS certificates**
3. **Restrict network access to your cluster**
4. **Use kubectl port-forwarding for secure access if needed**:
   ```powershell
   kubectl port-forward svc/guacamole-service 8080:80 -n guacamole
   # Then access via http://localhost:8080/guacamole
   ```

## Monitoring Your Deployment

```powershell
# Check all pods
kubectl get pods -n guacamole

# Check services
kubectl get svc -n guacamole

# Check logs if something fails
kubectl logs deployment/postgres -n guacamole
kubectl logs deployment/guacd -n guacamole
kubectl logs deployment/guacamole -n guacamole
```
