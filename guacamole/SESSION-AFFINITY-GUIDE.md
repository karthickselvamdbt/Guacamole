# TutorPro360 Session Affinity Configuration Guide

## Overview
This guide explains how TutorPro360 ensures that each participant (user session) works with one specific guacd daemon instance for consistent connection handling and optimal performance.

## Architecture

### Before (Load Balanced)
```
User Session 1 ──┐
User Session 2 ──┼─► Load Balancer ──┐
User Session 3 ──┘                   ├─► guacd-pod-1
                                     ├─► guacd-pod-2
                                     └─► guacd-pod-3
```
**Problem**: Users could connect to different guacd instances, causing session inconsistencies.

### After (Session Affinity)
```
User Session 1 ────────────────────► guacd-stateful-0 (Dedicated)
User Session 2 ────────────────────► guacd-stateful-1 (Dedicated)  
User Session 3 ────────────────────► guacd-stateful-2 (Dedicated)
```
**Solution**: Each user session is consistently routed to the same guacd instance.

## Implementation Details

### 1. StatefulSet Deployment
- **Component**: `guacd-stateful`
- **Replicas**: 3 pods with consistent naming
- **Pod Names**: `guacd-stateful-0`, `guacd-stateful-1`, `guacd-stateful-2`
- **Benefits**: Predictable pod names and stable network identities

### 2. Session Affinity Service
- **Service**: `guacd-service` with `sessionAffinity: ClientIP`
- **Timeout**: 3600 seconds (1 hour)
- **Behavior**: Routes users to the same guacd pod based on client IP

### 3. Individual Pod Services
- **guacd-0**: Direct access to `guacd-stateful-0`
- **guacd-1**: Direct access to `guacd-stateful-1`  
- **guacd-2**: Direct access to `guacd-stateful-2`

### 4. Headless Service
- **Service**: `guacd-headless`
- **Purpose**: Enables direct pod-to-pod communication
- **DNS**: Provides individual pod DNS names

## Configuration Files

### StatefulSet Configuration
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: guacd-stateful
spec:
  serviceName: guacd-headless
  replicas: 3
  # ... (see guacd-statefulset.yaml)
```

### Session Affinity Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: guacd-service
spec:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  # ... (see tutorpro360-services.yaml)
```

## Benefits for Educational Use

### 1. Consistent User Experience
- **Same guacd instance**: Each student connects to the same daemon
- **Session continuity**: No connection drops due to load balancing
- **Predictable performance**: Consistent response times per user

### 2. Resource Management
- **Dedicated resources**: Each guacd handles specific users
- **Load distribution**: Users evenly distributed across 3 instances
- **Scalability**: Can add more guacd instances as needed

### 3. Troubleshooting
- **User isolation**: Issues with one guacd don't affect others
- **Targeted debugging**: Can identify which guacd serves which users
- **Log correlation**: Easier to trace user-specific issues

## Monitoring and Management

### Check StatefulSet Status
```bash
kubectl get statefulset guacd-stateful -n guacamole
kubectl get pods -l app.kubernetes.io/instance=guacd-stateful -n guacamole
```

### Verify Session Affinity
```bash
kubectl describe service guacd-service -n guacamole
kubectl get endpoints guacd-service -n guacamole
```

### Check Individual Pod Services
```bash
kubectl get endpoints guacd-0 guacd-1 guacd-2 -n guacamole
```

### Monitor Resource Usage
```bash
kubectl top pods -l app.kubernetes.io/instance=guacd-stateful -n guacamole
```

## Session Affinity Behavior

### How It Works
1. **First Connection**: User connects and is assigned to a guacd pod based on IP hash
2. **Subsequent Connections**: Same user IP always routes to the same pod
3. **Session Timeout**: After 1 hour of inactivity, affinity can change
4. **Pod Failure**: If assigned pod fails, user is reassigned to available pod

### User Distribution
- **Algorithm**: Client IP hash modulo number of pods
- **Distribution**: Approximately equal distribution across 3 pods
- **Persistence**: Maintained for session timeout duration

## Troubleshooting

### Common Issues
1. **Pod Not Ready**: Check StatefulSet status and pod logs
2. **Service Not Routing**: Verify session affinity configuration
3. **Connection Drops**: Check network policies and timeouts

### Debug Commands
```bash
# Check pod logs
kubectl logs guacd-stateful-0 -n guacamole

# Test connectivity to specific pod
kubectl exec -it guacamole-working-xxx -n guacamole -- nc -zv guacd-0 4822

# Check service configuration
kubectl describe service guacd-service -n guacamole
```

## Performance Considerations

### Resource Allocation
- **CPU**: 100m request, 500m limit per pod
- **Memory**: 256Mi request, 512Mi limit per pod
- **Total**: 3 pods = 1.5 CPU cores, 1.5GB RAM maximum

### Scaling Recommendations
- **Small Classes**: 3 pods (current) - up to 60 concurrent users
- **Medium Classes**: 5 pods - up to 100 concurrent users  
- **Large Classes**: 10 pods - up to 200 concurrent users

### Monitoring Metrics
- **Connection Count**: Monitor active connections per pod
- **Resource Usage**: Track CPU and memory per pod
- **Response Time**: Monitor connection establishment time

## Security Considerations

### Network Policies
- **Pod-to-Pod**: Restricted communication between guacd pods
- **Service Access**: Only Guacamole pods can access guacd services
- **External Access**: No direct external access to guacd pods

### Session Security
- **IP-based Affinity**: Provides basic session consistency
- **Timeout**: 1-hour timeout prevents indefinite sessions
- **Isolation**: Each pod handles separate user groups

## Maintenance

### Rolling Updates
```bash
# Update StatefulSet
kubectl patch statefulset guacd-stateful -n guacamole -p '{"spec":{"updateStrategy":{"type":"RollingUpdate"}}}'

# Restart specific pod
kubectl delete pod guacd-stateful-0 -n guacamole
```

### Scaling Operations
```bash
# Scale up
kubectl scale statefulset guacd-stateful --replicas=5 -n guacamole

# Scale down
kubectl scale statefulset guacd-stateful --replicas=2 -n guacamole
```

## Conclusion

The session affinity configuration ensures that each TutorPro360 participant works with one dedicated guacd instance, providing:

- **Consistent Performance**: Predictable connection behavior
- **Better Resource Management**: Even load distribution
- **Improved Troubleshooting**: User-specific issue isolation
- **Educational Optimization**: Stable connections for learning environments

This setup is ideal for educational environments where consistent user experience and reliable connections are critical for effective learning.
