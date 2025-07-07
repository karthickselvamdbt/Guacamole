# Apache Guacamole Kubernetes Deployment

This directory contains production-ready Kubernetes manifests for deploying Apache Guacamole with PostgreSQL database and guacd daemon.

## Architecture

The deployment consists of:
- **PostgreSQL Database**: Persistent storage for Guacamole configuration and user data
- **Guacd Daemon**: Handles remote desktop protocol connections (RDP, SSH, VNC, etc.)
- **Guacamole Web Application**: Web-based remote desktop gateway

## Production Features

### Security
- ✅ Non-root containers with security contexts
- ✅ Read-only root filesystems where possible
- ✅ Network policies for pod-to-pod communication
- ✅ Secrets management for sensitive data
- ✅ TLS/HTTPS support via Ingress
- ✅ Security headers configuration
- ✅ Rate limiting

### High Availability
- ✅ Multiple replicas for Guacamole and guacd
- ✅ Pod Disruption Budgets
- ✅ Session affinity for consistent user experience
- ✅ Health checks (liveness and readiness probes)
- ✅ Horizontal Pod Autoscaling

### Performance & Monitoring
- ✅ Resource requests and limits
- ✅ JVM tuning for Guacamole
- ✅ PostgreSQL performance configuration
- ✅ Monitoring configuration ready
- ✅ Persistent storage for data

### Scalability
- ✅ Horizontal Pod Autoscaling based on CPU/Memory
- ✅ Persistent volumes for stateful components
- ✅ ConfigMaps for easy configuration management

## Prerequisites

1. **Kubernetes cluster** (1.19+)
2. **Ingress controller** (NGINX recommended)
3. **Storage class** for persistent volumes
4. **cert-manager** (optional, for automatic TLS certificates)

## Quick Start

### 1. Update Configuration

Before deploying, update the following files with your specific values:

**ingress.yaml**:
```yaml
- host: guacamole.yourdomain.com  # Replace with your domain
```

**persistent-volumes.yaml**:
```yaml
storageClassName: "your-storage-class"  # Replace with your storage class
```

### 2. Deploy

**Option A: Automated Deployment (Recommended)**
```powershell
# Run the automated deployment script
.\deploy.ps1
```

**Option B: Manual Deployment**
Deploy all components in order:

```powershell
# Create namespace and basic resources
kubectl apply -f namespace.yaml
kubectl apply -f secrets.yaml
kubectl apply -f configmaps.yaml
kubectl apply -f persistent-volumes.yaml

# Deploy database
kubectl apply -f postgres-deployment.yaml
kubectl apply -f services.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgres -n guacamole --timeout=300s

# Initialize database schema
kubectl apply -f guacamole-db-init-job.yaml

# Wait for database initialization to complete
kubectl wait --for=condition=complete job/guacamole-db-init -n guacamole --timeout=300s

# Deploy guacd daemon
kubectl apply -f guacd-deployment.yaml

# Deploy Guacamole web application
kubectl apply -f guacamole-deployment.yaml

# Apply production features
kubectl apply -f pod-disruption-budgets.yaml
kubectl apply -f horizontal-pod-autoscalers.yaml
kubectl apply -f security-policies.yaml

# Deploy ingress (update domain first!)
kubectl apply -f ingress.yaml

# Optional: Apply monitoring configuration
kubectl apply -f monitoring-config.yaml
```

### 3. Verify Deployment

```powershell
# Check all pods are running
kubectl get pods -n guacamole

# Check services
kubectl get svc -n guacamole

# Check ingress
kubectl get ingress -n guacamole

# View logs
kubectl logs -f deployment/guacamole -n guacamole
```

## Default Credentials

- **Username**: `guacadmin`
- **Password**: `guacadmin123`

**⚠️ IMPORTANT**: Change the default password immediately after first login!

**🔐 Security Note**: For production deployments, generate secure passwords using the provided script:
```powershell
.\generate-secrets.ps1
```

## Configuration

### Database
- **Host**: `postgres-service`
- **Database**: `guacamole_db`
- **Username**: `postgres`
- **Password**: `postgresadmin123` (change in secrets.yaml)

### Storage
- **PostgreSQL Data**: 20Gi persistent volume
- **Guacamole Extensions**: 1Gi persistent volume

### Resources
- **PostgreSQL**: 512Mi-2Gi RAM, 250m-1000m CPU
- **Guacamole**: 1Gi-2Gi RAM, 250m-1000m CPU
- **Guacd**: 256Mi-1Gi RAM, 100m-500m CPU

## Scaling

### Manual Scaling
```powershell
# Scale Guacamole pods
kubectl scale deployment guacamole --replicas=5 -n guacamole

# Scale guacd pods
kubectl scale deployment guacd --replicas=3 -n guacamole
```

### Auto Scaling
Horizontal Pod Autoscaling is configured to:
- **Guacamole**: 2-10 replicas based on 70% CPU, 80% memory
- **Guacd**: 2-5 replicas based on 70% CPU, 80% memory

## Monitoring

The deployment includes configuration for:
- Prometheus metrics collection
- Grafana dashboard template
- Application logs via kubectl

To enable monitoring:
1. Install Prometheus and Grafana in your cluster
2. Apply the monitoring configuration: `kubectl apply -f monitoring-config.yaml`
3. Import the Grafana dashboard from the ConfigMap

## Security Considerations

1. **Change default passwords** in secrets.yaml before deployment
2. **Update TLS certificates** - configure cert-manager or provide your own certificates
3. **Review network policies** - adjust based on your security requirements
4. **Enable audit logging** in your cluster
5. **Regular security updates** - monitor for new container image versions
6. **Backup strategy** - implement regular PostgreSQL backups

## Backup and Recovery

### Database Backup
```powershell
# Create a backup
kubectl exec -it deployment/postgres -n guacamole -- pg_dump -U postgres guacamole_db > guacamole-backup.sql

# Restore from backup
kubectl exec -i deployment/postgres -n guacamole -- psql -U postgres guacamole_db < guacamole-backup.sql
```

### Persistent Volume Backup
Use your cloud provider's volume snapshot feature or backup tools like Velero.

## Troubleshooting

### Automated Troubleshooting
```powershell
# Run comprehensive troubleshooting script
.\troubleshoot-deployment.ps1
```

### Common Issues

1. **Pods not starting**:
   - Check resource quotas: `kubectl describe nodes`
   - Verify storage class: `kubectl get storageclass`
   - Check events: `kubectl get events -n guacamole`

2. **Database connection errors**:
   - Verify PostgreSQL is running: `kubectl get pods -n guacamole -l app.kubernetes.io/name=postgres`
   - Check secrets: `kubectl get secrets -n guacamole`
   - Test connectivity: `kubectl exec -it deployment/guacamole -n guacamole -- nc -z postgres-service 5432`

3. **Session issues**:
   - Ensure session affinity is configured in the service/ingress
   - Check ingress controller logs
   - Verify cookie settings in ingress annotations

4. **Performance issues**:
   - Monitor resource usage: `kubectl top pods -n guacamole`
   - Check HPA status: `kubectl get hpa -n guacamole`
   - Adjust resource limits/requests as needed

5. **Access issues**:
   - Check service type and ports: `kubectl get svc -n guacamole`
   - Verify ingress configuration: `kubectl get ingress -n guacamole`
   - Test with port-forward: `kubectl port-forward svc/guacamole-service 8080:80 -n guacamole`

### Useful Commands
```powershell
# Check pod status
kubectl describe pod <pod-name> -n guacamole

# View logs
kubectl logs <pod-name> -n guacamole -f

# Check events
kubectl get events -n guacamole --sort-by='.lastTimestamp'

# Test connectivity
kubectl exec -it deployment/guacamole -n guacamole -- curl http://guacd-service:4822

# Access via port-forward (for testing)
kubectl port-forward svc/guacamole-service 8080:80 -n guacamole
```

## Customization

### Adding Extensions
1. Download Guacamole extensions (.jar files)
2. Create a new ConfigMap or use an init container to place them in `/etc/guacamole/extensions/`
3. Restart Guacamole pods

### Environment-Specific Changes
- **Development**: Reduce replicas to 1, remove resource limits
- **Staging**: Use smaller resource requests
- **Production**: Enable all monitoring, backup, and security features

## Support

For Apache Guacamole documentation and support:
- [Official Documentation](https://guacamole.apache.org/doc/gug/)
- [Apache Guacamole Manual](https://guacamole.apache.org/doc/gug/administration.html)
- [GitHub Repository](https://github.com/apache/guacamole-client)

## License

This deployment configuration is provided under the same license as Apache Guacamole (Apache License 2.0).
