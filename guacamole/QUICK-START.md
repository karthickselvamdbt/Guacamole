# 🚀 Quick Start Guide - Fixed Apache Guacamole Deployment

This guide will get you up and running with the fixed and improved Apache Guacamole Kubernetes deployment in minutes.

---

## ⚡ **Super Quick Start (2 minutes)**

```powershell
# 1. Setup cluster connection (if needed)
.\setup-cluster.ps1

# 2. Deploy everything
.\deploy.ps1

# 3. Check health
.\health-check.ps1
```

**Default Access:**
- **URL**: http://your-cluster-ip:30080
- **Username**: `guacadmin`
- **Password**: `guacadmin123`

---

## 🔒 **Secure Deployment (5 minutes)**

For production or security-conscious deployments:

```powershell
# 1. Generate secure passwords
.\generate-secrets.ps1

# 2. Review and apply the new secrets
# Check the generated secrets-new.yaml file
mv secrets-new.yaml secrets.yaml

# 3. Deploy with secure configuration
.\deploy.ps1

# 4. Optimize for your environment
.\optimize-resources.ps1 -Environment production

# 5. Verify deployment
.\health-check.ps1 -Detailed
```

**Note**: Save the generated passwords from step 1!

---

## 🛠️ **Prerequisites**

- **Kubernetes cluster** (1.19+) with kubectl configured
- **PowerShell** (Windows/Linux/macOS)
- **Storage class** available in your cluster
- **Ingress controller** (optional, for domain access)

### Quick Prerequisites Check
```powershell
# Test cluster connectivity
kubectl cluster-info

# Check available storage classes
kubectl get storageclass

# Check if you have an ingress controller
kubectl get pods -A | findstr ingress
```

---

## 📋 **Step-by-Step Deployment**

### Step 1: Prepare Your Environment
```powershell
# Clone or download the project files
# Ensure you're in the guacamole directory

# Test cluster connectivity
.\test-cluster.ps1
```

### Step 2: Configure (Optional)
```powershell
# For custom domains, edit ingress.yaml
# For custom storage, edit persistent-volumes.yaml
# For secure passwords, run:
.\generate-secrets.ps1
```

### Step 3: Deploy
```powershell
# Automated deployment
.\deploy.ps1

# The script will:
# - Create namespace and resources
# - Deploy PostgreSQL database
# - Initialize database schema
# - Deploy Guacd daemon
# - Deploy Guacamole web application
# - Apply production features
```

### Step 4: Verify
```powershell
# Check deployment health
.\health-check.ps1

# Check all pods are running
kubectl get pods -n guacamole

# Get access information
kubectl get svc -n guacamole
```

---

## 🌐 **Access Your Deployment**

### Method 1: NodePort (Default)
```powershell
# Get your cluster node IPs
kubectl get nodes -o wide

# Access via: http://NODE-IP:30080
```

### Method 2: Port Forward (Testing)
```powershell
# Forward local port to service
kubectl port-forward svc/guacamole-service 8080:80 -n guacamole

# Access via: http://localhost:8080
```

### Method 3: Ingress (Domain Access)
```powershell
# If you have an ingress controller
kubectl get ingress -n guacamole

# Access via the configured domain
```

---

## 🔧 **Common Tasks**

### Scale Your Deployment
```powershell
# Scale Guacamole pods
kubectl scale deployment guacamole --replicas=5 -n guacamole

# Scale Guacd pods
kubectl scale deployment guacd --replicas=3 -n guacamole
```

### Create a Backup
```powershell
# Create database backup
.\backup-database.ps1

# Backups are stored in ./backups/ directory
```

### Monitor Health
```powershell
# One-time health check
.\health-check.ps1

# Continuous monitoring (every 30 seconds)
.\health-check.ps1 -Continuous -Interval 30
```

### Troubleshoot Issues
```powershell
# Comprehensive troubleshooting
.\troubleshoot-deployment.ps1

# Check specific component logs
kubectl logs -n guacamole deployment/guacamole
kubectl logs -n guacamole deployment/postgres
kubectl logs -n guacamole deployment/guacd
```

---

## 🎯 **Environment Optimization**

### Development Environment
```powershell
.\optimize-resources.ps1 -Environment development
# - Minimal resources
# - Single replicas
# - Faster startup
```

### Staging Environment
```powershell
.\optimize-resources.ps1 -Environment staging
# - Moderate resources
# - 2 replicas for testing HA
# - Production-like setup
```

### Production Environment
```powershell
.\optimize-resources.ps1 -Environment production
# - Full resources
# - 3 replicas for HA
# - Optimized for performance
```

---

## 🧹 **Cleanup**

### Standard Cleanup
```powershell
# Remove all resources
.\cleanup.ps1
```

### Advanced Cleanup with Backup
```powershell
# Backup before cleanup, keep persistent volumes
.\cleanup-advanced.ps1 -BackupBeforeCleanup -KeepPersistentVolumes
```

### Force Cleanup (No Prompts)
```powershell
# Force cleanup without prompts
.\cleanup-advanced.ps1 -Force
```

---

## 🆘 **Troubleshooting Quick Fixes**

### Pods Not Starting
```powershell
# Check events
kubectl get events -n guacamole --sort-by='.lastTimestamp'

# Check node resources
kubectl describe nodes

# Check storage
kubectl get pvc -n guacamole
```

### Can't Access Guacamole
```powershell
# Check service
kubectl get svc -n guacamole

# Test with port-forward
kubectl port-forward svc/guacamole-service 8080:80 -n guacamole

# Check ingress
kubectl get ingress -n guacamole
```

### Database Issues
```powershell
# Check PostgreSQL logs
kubectl logs -n guacamole deployment/postgres

# Check database initialization
kubectl logs -n guacamole job/guacamole-db-init

# Test database connectivity
kubectl exec -it deployment/postgres -n guacamole -- psql -U postgres -d guacamole_db -c "\dt"
```

---

## 📚 **What's New in This Fixed Version**

✅ **Secure by default** - Proper secret management  
✅ **Production ready** - Backup, monitoring, health checks  
✅ **Easy to use** - Automated scripts and clear documentation  
✅ **Comprehensive tooling** - Troubleshooting, optimization, cleanup  
✅ **Flexible deployment** - Environment-specific configurations  
✅ **Better reliability** - Improved health checks and error handling  

---

## 🎉 **Success!**

If everything is working:
- ✅ Pods are running: `kubectl get pods -n guacamole`
- ✅ Services are accessible: `kubectl get svc -n guacamole`
- ✅ Health check passes: `.\health-check.ps1`
- ✅ You can log in to Guacamole web interface

**Next Steps:**
1. Change the default password
2. Add your remote desktop connections
3. Create additional users
4. Set up regular backups
5. Configure monitoring

---

**Need help?** Check the comprehensive documentation in `README.md` or run `.\troubleshoot-deployment.ps1`
