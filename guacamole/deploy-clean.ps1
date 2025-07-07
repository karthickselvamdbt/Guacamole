#!/usr/bin/env powershell
# Complete Clean and Deploy Script for Apache Guacamole
# This script will delete everything and redeploy from scratch

param(
    [switch]$Force = $false
)

Write-Host "=== Apache Guacamole - Complete Clean & Deploy ===" -ForegroundColor Green

# Function to check if command succeeded
function Test-CommandSuccess {
    param([string]$Description)
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $Description" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ $Description failed" -ForegroundColor Red
        return $false
    }
}

# Warning and confirmation
if (-not $Force) {
    Write-Host "`n⚠️  WARNING: This will completely delete and redeploy Guacamole!" -ForegroundColor Red
    Write-Host "This includes:" -ForegroundColor Red
    Write-Host "- All existing pods, services, and deployments" -ForegroundColor Red
    Write-Host "- All data and configurations" -ForegroundColor Red
    Write-Host "- The entire 'guacamole' namespace" -ForegroundColor Red
    
    $confirmation = Read-Host "`nType 'DEPLOY' to confirm complete clean and redeploy"
    if ($confirmation -ne "DEPLOY") {
        Write-Host "Operation cancelled by user" -ForegroundColor Yellow
        exit 0
    }
}

# Pre-deployment checks
Write-Host "`n=== Pre-Deployment Checks ===" -ForegroundColor Cyan
kubectl cluster-info --request-timeout=10s | Out-Null
if (-not (Test-CommandSuccess "Kubernetes cluster connectivity")) {
    Write-Host "Please ensure kubectl is configured and cluster is accessible" -ForegroundColor Red
    exit 1
}

# Step 1: Complete Cleanup
Write-Host "`n=== Step 1: Complete Cleanup ===" -ForegroundColor Cyan
Write-Host "Deleting existing Guacamole namespace..." -ForegroundColor Yellow

$namespaceExists = kubectl get namespace guacamole 2>$null
if ($namespaceExists) {
    kubectl delete namespace guacamole --timeout=120s
    if (Test-CommandSuccess "Namespace deletion") {
        Write-Host "✓ Cleanup completed!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Namespace deletion may be in progress..." -ForegroundColor Yellow
    }
    
    # Wait for namespace to be fully deleted
    Write-Host "Waiting for complete cleanup..." -ForegroundColor Yellow
    $timeout = 60
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        $namespaceStatus = kubectl get namespace guacamole 2>$null
        if (-not $namespaceStatus) {
            break
        }
        Start-Sleep -Seconds 2
        $elapsed += 2
        Write-Host "." -NoNewline
    }
    Write-Host ""
} else {
    Write-Host "✓ No existing deployment found" -ForegroundColor Green
}

# Step 2: Fresh Deployment
Write-Host "`n=== Step 2: Fresh Deployment ===" -ForegroundColor Cyan

# Create namespace and basic resources
Write-Host "`nCreating namespace and basic resources..." -ForegroundColor Yellow
kubectl apply -f namespace.yaml
Test-CommandSuccess "Namespace creation"

kubectl apply -f secrets.yaml
Test-CommandSuccess "Secrets creation"

kubectl apply -f configmaps.yaml
Test-CommandSuccess "ConfigMaps creation"

kubectl apply -f persistent-volumes.yaml
Test-CommandSuccess "Persistent volumes creation"

# Deploy PostgreSQL database
Write-Host "`nDeploying PostgreSQL database..." -ForegroundColor Yellow
kubectl apply -f postgres-simple.yaml
Test-CommandSuccess "PostgreSQL deployment"

kubectl apply -f services.yaml
Test-CommandSuccess "Services creation"

# Wait for PostgreSQL to be ready
Write-Host "`nWaiting for PostgreSQL to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgres -n guacamole --timeout=300s
Test-CommandSuccess "PostgreSQL readiness"

# Initialize database schema
Write-Host "`nInitializing database schema..." -ForegroundColor Yellow
$podName = kubectl get pods -n guacamole -l app.kubernetes.io/name=postgres -o jsonpath="{.items[0].metadata.name}"
kubectl run guacamole-init --image=guacamole/guacamole:1.5.4 --rm -it --restart=Never -n guacamole -- /opt/guacamole/bin/initdb.sh --postgresql | kubectl exec -i $podName -n guacamole -- psql -U postgres -d guacamole_db
Test-CommandSuccess "Database schema initialization"

# Deploy Guacd daemon
Write-Host "`nDeploying Guacd daemon..." -ForegroundColor Yellow
kubectl apply -f guacd-deployment.yaml
Test-CommandSuccess "Guacd deployment"

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=guacd -n guacamole --timeout=300s
Test-CommandSuccess "Guacd readiness"

# Deploy Guacamole web application
Write-Host "`nDeploying Guacamole web application..." -ForegroundColor Yellow
kubectl apply -f guacamole-deployment-working.yaml
Test-CommandSuccess "Guacamole deployment"

kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=guacamole-working -n guacamole --timeout=300s
Test-CommandSuccess "Guacamole readiness"

# Apply production features
Write-Host "`nApplying production features..." -ForegroundColor Yellow
kubectl apply -f horizontal-pod-autoscalers.yaml
Test-CommandSuccess "Horizontal Pod Autoscalers"

kubectl apply -f pod-disruption-budgets.yaml
Test-CommandSuccess "Pod Disruption Budgets"

# Step 3: Verification
Write-Host "`n=== Step 3: Verification ===" -ForegroundColor Cyan

# Get node IPs for access information
$nodeIPs = kubectl get nodes -o jsonpath="{.items[*].status.addresses[?(@.type=='InternalIP')].address}"
$firstNodeIP = $nodeIPs.Split(' ')[0]

# Test service connectivity
Write-Host "Testing service connectivity..." -ForegroundColor Yellow
try {
    Start-Sleep -Seconds 10  # Give the service a moment to be ready
    $response = Invoke-WebRequest -Uri "http://$firstNodeIP:30562/" -Method Head -TimeoutSec 15
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Guacamole service is accessible!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Service returned status code: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Service connectivity test failed, but deployment may still be starting..." -ForegroundColor Yellow
}

# Check PostgreSQL extension
Write-Host "Checking PostgreSQL extension..." -ForegroundColor Yellow
$logs = kubectl logs -l app.kubernetes.io/instance=guacamole-working -n guacamole --tail=20
if ($logs -match "Extension.*PostgreSQL Authentication.*loaded") {
    Write-Host "✓ PostgreSQL extension loaded successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  PostgreSQL extension status unclear, check logs manually" -ForegroundColor Yellow
}

# Final status
Write-Host "`nFinal deployment status:" -ForegroundColor Cyan
kubectl get all -n guacamole

# Step 4: Success Summary
Write-Host "`n=== Deployment Complete! ===" -ForegroundColor Green

Write-Host "`n🌐 Access URLs:" -ForegroundColor Cyan
foreach ($ip in $nodeIPs.Split(' ')) {
    if ($ip.Trim()) {
        Write-Host "   http://$($ip.Trim()):30562" -ForegroundColor White
    }
}

Write-Host "`n🔐 Default Credentials:" -ForegroundColor Cyan
Write-Host "   Username: guacadmin" -ForegroundColor White
Write-Host "   Password: guacadmin" -ForegroundColor White

Write-Host "`n⚠️  Important Next Steps:" -ForegroundColor Yellow
Write-Host "1. Access the web interface and log in" -ForegroundColor White
Write-Host "2. Change the default password immediately" -ForegroundColor White
Write-Host "3. Add your remote desktop connections" -ForegroundColor White
Write-Host "4. Create additional users as needed" -ForegroundColor White

Write-Host "`n🛠️  Management Commands:" -ForegroundColor Cyan
Write-Host "   Health Check: .\health-check.ps1" -ForegroundColor White
Write-Host "   Backup: .\backup-database.ps1" -ForegroundColor White
Write-Host "   Troubleshoot: .\troubleshoot-deployment.ps1" -ForegroundColor White
Write-Host "   Clean Redeploy: .\deploy-clean.ps1 -Force" -ForegroundColor White

Write-Host "`n🎉 Apache Guacamole is ready to use!" -ForegroundColor Green
Write-Host "Primary URL: http://$firstNodeIP:30562" -ForegroundColor Cyan

# Open browser if possible
try {
    Write-Host "`nOpening browser..." -ForegroundColor Yellow
    Start-Process "http://$firstNodeIP:30562"
} catch {
    Write-Host "Could not open browser automatically. Please open manually." -ForegroundColor Yellow
}
