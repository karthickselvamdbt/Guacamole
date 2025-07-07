#!/usr/bin/env powershell
# TutorPro360 Deployment Script - Complete Clean and Deploy with Custom Branding

param(
    [switch]$Force = $false
)

Write-Host "=== TutorPro360 - Educational Remote Access Platform ===" -ForegroundColor Blue
Write-Host "Complete Clean & Deploy with Custom Branding" -ForegroundColor Cyan

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
    Write-Host "`n⚠️  This will deploy TutorPro360 with custom branding!" -ForegroundColor Yellow
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "- Replace any existing Guacamole deployment" -ForegroundColor Yellow
    Write-Host "- Deploy with TutorPro360 branding and logo" -ForegroundColor Yellow
    Write-Host "- Use custom port 30360 for access" -ForegroundColor Yellow
    
    $confirmation = Read-Host "`nType 'TUTORPRO360' to confirm deployment"
    if ($confirmation -ne "TUTORPRO360") {
        Write-Host "Deployment cancelled by user" -ForegroundColor Yellow
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

# Step 1: Cleanup existing deployment
Write-Host "`n=== Step 1: Cleanup Existing Deployment ===" -ForegroundColor Cyan
$namespaceExists = kubectl get namespace guacamole 2>$null
if ($namespaceExists) {
    Write-Host "Cleaning up existing deployment..." -ForegroundColor Yellow
    kubectl delete namespace guacamole --timeout=120s
    Test-CommandSuccess "Cleanup"
    
    # Wait for complete cleanup
    Write-Host "Waiting for complete cleanup..." -ForegroundColor Yellow
    $timeout = 60
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        $namespaceStatus = kubectl get namespace guacamole 2>$null
        if (-not $namespaceStatus) { break }
        Start-Sleep -Seconds 2
        $elapsed += 2
        Write-Host "." -NoNewline
    }
    Write-Host ""
}

# Step 2: Deploy TutorPro360
Write-Host "`n=== Step 2: Deploying TutorPro360 ===" -ForegroundColor Cyan

# Create namespace and basic resources
Write-Host "`nCreating namespace and basic resources..." -ForegroundColor Yellow
kubectl apply -f namespace.yaml
Test-CommandSuccess "Namespace creation"

kubectl apply -f secrets.yaml
Test-CommandSuccess "Secrets creation"

kubectl apply -f configmaps.yaml
Test-CommandSuccess "ConfigMaps creation"

# Apply TutorPro360 branding
Write-Host "`nApplying TutorPro360 branding..." -ForegroundColor Yellow
kubectl apply -f tutorpro360-branding.yaml
Test-CommandSuccess "TutorPro360 branding"

kubectl apply -f tutorpro360-config.yaml
Test-CommandSuccess "TutorPro360 configuration"

kubectl apply -f persistent-volumes.yaml
Test-CommandSuccess "Persistent volumes"

# Deploy database
Write-Host "`nDeploying PostgreSQL database..." -ForegroundColor Yellow
kubectl apply -f postgres-simple.yaml
Test-CommandSuccess "PostgreSQL deployment"

# Deploy services
Write-Host "`nDeploying TutorPro360 services..." -ForegroundColor Yellow
kubectl apply -f tutorpro360-services.yaml
Test-CommandSuccess "TutorPro360 services"

# Wait for PostgreSQL
Write-Host "`nWaiting for PostgreSQL..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgres -n guacamole --timeout=300s
Test-CommandSuccess "PostgreSQL readiness"

# Initialize database
Write-Host "`nInitializing database..." -ForegroundColor Yellow
$podName = kubectl get pods -n guacamole -l app.kubernetes.io/name=postgres -o jsonpath="{.items[0].metadata.name}"
kubectl run guacamole-init --image=guacamole/guacamole:1.5.4 --rm -it --restart=Never -n guacamole -- /opt/guacamole/bin/initdb.sh --postgresql | kubectl exec -i $podName -n guacamole -- psql -U postgres -d guacamole_db
Test-CommandSuccess "Database initialization"

# Deploy Guacd
Write-Host "`nDeploying Guacd daemon..." -ForegroundColor Yellow
kubectl apply -f guacd-deployment.yaml
Test-CommandSuccess "Guacd deployment"

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=guacd -n guacamole --timeout=300s
Test-CommandSuccess "Guacd readiness"

# Deploy TutorPro360 web application
Write-Host "`nDeploying TutorPro360 web application..." -ForegroundColor Yellow
kubectl apply -f tutorpro360-deployment.yaml
Test-CommandSuccess "TutorPro360 deployment"

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=tutorpro360 -n guacamole --timeout=300s
Test-CommandSuccess "TutorPro360 readiness"

# Apply production features
Write-Host "`nApplying production features..." -ForegroundColor Yellow
kubectl apply -f horizontal-pod-autoscalers.yaml
Test-CommandSuccess "Auto-scaling"

kubectl apply -f pod-disruption-budgets.yaml
Test-CommandSuccess "Disruption budgets"

# Step 3: Verification
Write-Host "`n=== Step 3: Verification ===" -ForegroundColor Cyan

# Get access information
$nodeIPs = kubectl get nodes -o jsonpath="{.items[*].status.addresses[?(@.type=='InternalIP')].address}"
$firstNodeIP = $nodeIPs.Split(' ')[0]

# Test connectivity
Write-Host "Testing TutorPro360 connectivity..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
try {
    $response = Invoke-WebRequest -Uri "http://$firstNodeIP:30360/" -Method Head -TimeoutSec 15
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ TutorPro360 is accessible!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Service may still be starting..." -ForegroundColor Yellow
}

# Final status
Write-Host "`nDeployment status:" -ForegroundColor Cyan
kubectl get all -n guacamole

# Success summary
Write-Host "`n=== TutorPro360 Deployment Complete! ===" -ForegroundColor Green

Write-Host "`n🌐 TutorPro360 Access URLs:" -ForegroundColor Cyan
foreach ($ip in $nodeIPs.Split(' ')) {
    if ($ip.Trim()) {
        Write-Host "   http://$($ip.Trim()):30360" -ForegroundColor White
    }
}

Write-Host "`n🔐 Default Credentials:" -ForegroundColor Cyan
Write-Host "   Username: guacadmin" -ForegroundColor White
Write-Host "   Password: guacadmin" -ForegroundColor White

Write-Host "`n🎨 Custom Features:" -ForegroundColor Cyan
Write-Host "   ✓ TutorPro360 branding and logo" -ForegroundColor Green
Write-Host "   ✓ Custom color scheme (Blue/Cyan)" -ForegroundColor Green
Write-Host "   ✓ Educational theme" -ForegroundColor Green
Write-Host "   ✓ Custom port 30360" -ForegroundColor Green

Write-Host "`n⚠️  Next Steps:" -ForegroundColor Yellow
Write-Host "1. Access TutorPro360 and log in" -ForegroundColor White
Write-Host "2. Change default password" -ForegroundColor White
Write-Host "3. Configure educational connections" -ForegroundColor White
Write-Host "4. Create student/teacher accounts" -ForegroundColor White

Write-Host "`n🎉 TutorPro360 Educational Platform is ready!" -ForegroundColor Green
Write-Host "Primary URL: http://$firstNodeIP:30360" -ForegroundColor Cyan

# Open browser
try {
    Write-Host "`nOpening TutorPro360..." -ForegroundColor Yellow
    Start-Process "http://$firstNodeIP:30360"
} catch {
    Write-Host "Please open browser manually to: http://$firstNodeIP:30360" -ForegroundColor Yellow
}
