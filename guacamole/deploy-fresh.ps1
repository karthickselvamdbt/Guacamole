#!/usr/bin/env powershell
# Fresh deployment script for Apache Guacamole with all fixes

Write-Host "=== Fresh Apache Guacamole Deployment ===" -ForegroundColor Green

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

# Pre-deployment checks
Write-Host "`nPerforming pre-deployment checks..." -ForegroundColor Yellow

# Check kubectl connectivity
kubectl cluster-info --request-timeout=10s | Out-Null
if (-not (Test-CommandSuccess "Kubernetes cluster connectivity")) {
    Write-Host "Please ensure kubectl is configured and cluster is accessible" -ForegroundColor Red
    exit 1
}

# Step 1: Create namespace and basic resources
Write-Host "`n=== Step 1: Creating namespace and basic resources ===" -ForegroundColor Cyan
kubectl apply -f namespace.yaml
Test-CommandSuccess "Namespace creation"

kubectl apply -f secrets.yaml
Test-CommandSuccess "Secrets creation"

kubectl apply -f configmaps.yaml
Test-CommandSuccess "ConfigMaps creation"

kubectl apply -f persistent-volumes.yaml
Test-CommandSuccess "Persistent volumes creation"

# Step 2: Deploy PostgreSQL database
Write-Host "`n=== Step 2: Deploying PostgreSQL database ===" -ForegroundColor Cyan
kubectl apply -f postgres-deployment.yaml
Test-CommandSuccess "PostgreSQL deployment"

kubectl apply -f services.yaml
Test-CommandSuccess "Services creation"

# Wait for PostgreSQL to be ready
Write-Host "`nWaiting for PostgreSQL to be ready (timeout: 5 minutes)..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgres-simple -n guacamole --timeout=300s

if (-not (Test-CommandSuccess "PostgreSQL readiness")) {
    Write-Host "PostgreSQL deployment failed. Checking logs..." -ForegroundColor Red
    kubectl logs -l app.kubernetes.io/name=postgres-simple -n guacamole --tail=20
    exit 1
}

Write-Host "✓ PostgreSQL is ready!" -ForegroundColor Green

# Step 3: Initialize database schema
Write-Host "`n=== Step 3: Initializing database schema ===" -ForegroundColor Cyan

# Generate and apply database schema
Write-Host "Generating database schema..." -ForegroundColor Yellow
kubectl run guacamole-init --image=guacamole/guacamole:1.5.4 --rm -it --restart=Never -n guacamole -- /opt/guacamole/bin/initdb.sh --postgresql | kubectl exec -i postgres-simple-64585fdf8d-p72w5 -n guacamole -- psql -U postgres -d guacamole_db

if (Test-CommandSuccess "Database schema initialization") {
    Write-Host "✓ Database schema initialized successfully!" -ForegroundColor Green
} else {
    Write-Host "Database initialization failed. Trying alternative method..." -ForegroundColor Yellow
    
    # Alternative: Use the database init job
    kubectl apply -f guacamole-db-init-job.yaml
    kubectl wait --for=condition=complete job/guacamole-db-init -n guacamole --timeout=300s
    
    if (Test-CommandSuccess "Database initialization job") {
        Write-Host "✓ Database initialized via job!" -ForegroundColor Green
    } else {
        Write-Host "Database initialization failed completely" -ForegroundColor Red
        exit 1
    }
}

# Step 4: Deploy Guacd daemon
Write-Host "`n=== Step 4: Deploying Guacd daemon ===" -ForegroundColor Cyan
kubectl apply -f guacd-deployment.yaml
Test-CommandSuccess "Guacd deployment"

# Wait for Guacd to be ready
Write-Host "Waiting for Guacd to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=guacd -n guacamole --timeout=300s
Test-CommandSuccess "Guacd readiness"

# Step 5: Deploy Guacamole web application (working version)
Write-Host "`n=== Step 5: Deploying Guacamole web application ===" -ForegroundColor Cyan
kubectl apply -f guacamole-deployment-working.yaml
Test-CommandSuccess "Guacamole deployment"

# Wait for Guacamole to be ready
Write-Host "Waiting for Guacamole to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=guacamole-working -n guacamole --timeout=300s

if (Test-CommandSuccess "Guacamole readiness") {
    Write-Host "✓ Guacamole is ready!" -ForegroundColor Green
} else {
    Write-Host "Checking Guacamole logs..." -ForegroundColor Yellow
    kubectl logs -l app.kubernetes.io/instance=guacamole-working -n guacamole --tail=20
}

# Step 6: Apply production features
Write-Host "`n=== Step 6: Applying production features ===" -ForegroundColor Cyan
kubectl apply -f horizontal-pod-autoscalers.yaml
Test-CommandSuccess "Horizontal Pod Autoscalers"

kubectl apply -f pod-disruption-budgets.yaml
Test-CommandSuccess "Pod Disruption Budgets"

# Step 7: Verify deployment
Write-Host "`n=== Step 7: Verifying deployment ===" -ForegroundColor Cyan

# Get node IPs for access information
$nodeIPs = kubectl get nodes -o jsonpath="{.items[*].status.addresses[?(@.type=='InternalIP')].address}"
$firstNodeIP = $nodeIPs.Split(' ')[0]

# Test service connectivity
Write-Host "Testing service connectivity..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$firstNodeIP:30562/guacamole/" -Method Head -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Guacamole service is accessible!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Service returned status code: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not test service connectivity: $_" -ForegroundColor Yellow
}

# Final status check
Write-Host "`nFinal deployment status:" -ForegroundColor Cyan
kubectl get all -n guacamole

Write-Host "`n=== Deployment Complete! ===" -ForegroundColor Green
Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
foreach ($ip in $nodeIPs.Split(' ')) {
    if ($ip) {
        Write-Host "   http://$ip:30562/guacamole/" -ForegroundColor White
    }
}

Write-Host "`n🔐 Default Credentials:" -ForegroundColor Cyan
Write-Host "   Username: guacadmin" -ForegroundColor White
Write-Host "   Password: guacadmin" -ForegroundColor White

Write-Host "`n⚠️  Important:" -ForegroundColor Yellow
Write-Host "1. Change the default password immediately after login" -ForegroundColor White
Write-Host "2. Add your remote desktop connections" -ForegroundColor White
Write-Host "3. Create additional users as needed" -ForegroundColor White

Write-Host "`n🛠️  Management Tools:" -ForegroundColor Cyan
Write-Host "   Health Check: .\health-check.ps1" -ForegroundColor White
Write-Host "   Backup: .\backup-database.ps1" -ForegroundColor White
Write-Host "   Troubleshoot: .\troubleshoot-deployment.ps1" -ForegroundColor White

Write-Host "`n🎉 Apache Guacamole is ready to use!" -ForegroundColor Green
