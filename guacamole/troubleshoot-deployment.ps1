#!/usr/bin/env powershell
# Comprehensive troubleshooting script for Guacamole deployment

Write-Host "=== Guacamole Deployment Troubleshooting ===" -ForegroundColor Green

$namespace = "guacamole"

# Function to print section headers
function Write-Section {
    param([string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

# Function to run command and show output
function Invoke-DiagnosticCommand {
    param(
        [string]$Description,
        [string]$Command
    )
    Write-Host "`n$Description" -ForegroundColor Yellow
    Write-Host "Command: $Command" -ForegroundColor Gray
    try {
        Invoke-Expression $Command
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Check cluster connectivity
Write-Section "Cluster Connectivity"
Invoke-DiagnosticCommand "Cluster info" "kubectl cluster-info"
Invoke-DiagnosticCommand "Node status" "kubectl get nodes -o wide"

# Check namespace
Write-Section "Namespace Status"
Invoke-DiagnosticCommand "Namespace details" "kubectl get namespace $namespace -o yaml"

# Check all resources in namespace
Write-Section "All Resources"
Invoke-DiagnosticCommand "All resources in namespace" "kubectl get all -n $namespace"

# Check pods in detail
Write-Section "Pod Status"
Invoke-DiagnosticCommand "Pod details" "kubectl get pods -n $namespace -o wide"
Invoke-DiagnosticCommand "Pod descriptions" "kubectl describe pods -n $namespace"

# Check services
Write-Section "Service Status"
Invoke-DiagnosticCommand "Services" "kubectl get svc -n $namespace -o wide"
Invoke-DiagnosticCommand "Endpoints" "kubectl get endpoints -n $namespace"

# Check persistent volumes
Write-Section "Storage"
Invoke-DiagnosticCommand "Persistent Volumes" "kubectl get pv"
Invoke-DiagnosticCommand "Persistent Volume Claims" "kubectl get pvc -n $namespace"
Invoke-DiagnosticCommand "Storage Classes" "kubectl get storageclass"

# Check secrets and configmaps
Write-Section "Configuration"
Invoke-DiagnosticCommand "Secrets" "kubectl get secrets -n $namespace"
Invoke-DiagnosticCommand "ConfigMaps" "kubectl get configmaps -n $namespace"

# Check ingress
Write-Section "Ingress"
Invoke-DiagnosticCommand "Ingress resources" "kubectl get ingress -n $namespace -o wide"
Invoke-DiagnosticCommand "Ingress controllers" "kubectl get pods -A | findstr ingress"

# Check events
Write-Section "Recent Events"
Invoke-DiagnosticCommand "Events in namespace" "kubectl get events -n $namespace --sort-by='.lastTimestamp'"

# Check logs for each component
Write-Section "Component Logs"

$components = @("postgres", "guacd", "guacamole")
foreach ($component in $components) {
    Write-Host "`n--- $component logs ---" -ForegroundColor Yellow
    try {
        $pods = kubectl get pods -n $namespace -l "app.kubernetes.io/name=$component" -o jsonpath="{.items[*].metadata.name}" 2>$null
        if ($pods) {
            foreach ($pod in $pods.Split(' ')) {
                if ($pod) {
                    Write-Host "Logs for pod: $pod" -ForegroundColor Gray
                    kubectl logs $pod -n $namespace --tail=20
                }
            }
        } else {
            Write-Host "No pods found for component: $component" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error getting logs for $component`: $_" -ForegroundColor Red
    }
}

# Check database initialization job
Write-Section "Database Initialization"
Invoke-DiagnosticCommand "Database init job" "kubectl get jobs -n $namespace"
Invoke-DiagnosticCommand "Database init job logs" "kubectl logs job/guacamole-db-init -n $namespace"

# Network connectivity tests
Write-Section "Network Connectivity"
Write-Host "`nTesting internal service connectivity..." -ForegroundColor Yellow

# Test if we can create a test pod for network testing
try {
    kubectl run network-test --image=busybox:1.35 --rm -it --restart=Never -n $namespace -- /bin/sh -c "
        echo 'Testing PostgreSQL connectivity...'
        nc -z postgres-service 5432 && echo 'PostgreSQL: OK' || echo 'PostgreSQL: FAILED'
        echo 'Testing Guacd connectivity...'
        nc -z guacd-service 4822 && echo 'Guacd: OK' || echo 'Guacd: FAILED'
        echo 'Testing Guacamole connectivity...'
        nc -z guacamole-service 80 && echo 'Guacamole: OK' || echo 'Guacamole: FAILED'
    " 2>$null
} catch {
    Write-Host "Could not run network connectivity test: $_" -ForegroundColor Red
}

# Summary and recommendations
Write-Section "Summary and Recommendations"
Write-Host "`nCommon issues and solutions:" -ForegroundColor Yellow
Write-Host "1. Pods stuck in Pending: Check resource quotas and storage classes" -ForegroundColor White
Write-Host "2. Pods in CrashLoopBackOff: Check logs and resource limits" -ForegroundColor White
Write-Host "3. Service not accessible: Check ingress controller and network policies" -ForegroundColor White
Write-Host "4. Database connection issues: Verify secrets and service names" -ForegroundColor White
Write-Host "5. Storage issues: Ensure storage class exists and has capacity" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Review the logs above for specific error messages" -ForegroundColor White
Write-Host "2. Check resource usage: kubectl top pods -n $namespace" -ForegroundColor White
Write-Host "3. Verify cluster has sufficient resources: kubectl describe nodes" -ForegroundColor White
Write-Host "4. Test external access: kubectl port-forward svc/guacamole-service 8080:80 -n $namespace" -ForegroundColor White

Write-Host "`n=== Troubleshooting Complete ===" -ForegroundColor Green
