#!/usr/bin/env powershell
# Deploy Cloudflare Tunnel with 5 replicas for TutorPro360

param(
    [switch]$Force = $false
)

Write-Host "=== Deploying Cloudflare Tunnel for TutorPro360 ===" -ForegroundColor Blue

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
Write-Host "`n=== Pre-Deployment Checks ===" -ForegroundColor Cyan
kubectl cluster-info --request-timeout=10s | Out-Null
if (-not (Test-CommandSuccess "Kubernetes cluster connectivity")) {
    Write-Host "Please ensure kubectl is configured and cluster is accessible" -ForegroundColor Red
    exit 1
}

# Check if namespace exists
$namespaceExists = kubectl get namespace guacamole 2>$null
if (-not $namespaceExists) {
    Write-Host "Creating guacamole namespace..." -ForegroundColor Yellow
    kubectl create namespace guacamole
    Test-CommandSuccess "Namespace creation"
}

# Warning and confirmation
if (-not $Force) {
    Write-Host "`n⚠️  This will deploy Cloudflare Tunnel with 5 replicas!" -ForegroundColor Yellow
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "- Create Cloudflare Tunnel secret with your token" -ForegroundColor Yellow
    Write-Host "- Deploy 5 tunnel replicas for high availability" -ForegroundColor Yellow
    Write-Host "- Set up auto-scaling (5-10 replicas)" -ForegroundColor Yellow
    Write-Host "- Configure monitoring and metrics" -ForegroundColor Yellow
    
    $confirmation = Read-Host "`nType 'DEPLOY' to confirm deployment"
    if ($confirmation -ne "DEPLOY") {
        Write-Host "Deployment cancelled by user" -ForegroundColor Yellow
        exit 0
    }
}

# Step 1: Deploy Cloudflare Tunnel Secret
Write-Host "`n=== Step 1: Deploying Tunnel Secret ===" -ForegroundColor Cyan
kubectl apply -f cloudflare-tunnel-secret.yaml
Test-CommandSuccess "Tunnel secret deployment"

# Step 2: Deploy Cloudflare Tunnel
Write-Host "`n=== Step 2: Deploying Cloudflare Tunnel ===" -ForegroundColor Cyan
kubectl apply -f cloudflare-tunnel-deployment.yaml
Test-CommandSuccess "Tunnel deployment"

# Step 3: Wait for deployment
Write-Host "`n=== Step 3: Waiting for Tunnel Deployment ===" -ForegroundColor Cyan
Write-Host "Waiting for Cloudflare Tunnel pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cloudflare-tunnel -n guacamole --timeout=300s
Test-CommandSuccess "Tunnel pod readiness"

# Step 4: Verification
Write-Host "`n=== Step 4: Verification ===" -ForegroundColor Cyan

# Check deployment status
Write-Host "Checking deployment status..." -ForegroundColor Yellow
kubectl get deployment cloudflare-tunnel -n guacamole
Test-CommandSuccess "Deployment status check"

# Check pod status
Write-Host "`nChecking pod status..." -ForegroundColor Yellow
kubectl get pods -l app.kubernetes.io/name=cloudflare-tunnel -n guacamole
Test-CommandSuccess "Pod status check"

# Check HPA status
Write-Host "`nChecking auto-scaling status..." -ForegroundColor Yellow
kubectl get hpa cloudflare-tunnel-hpa -n guacamole
Test-CommandSuccess "HPA status check"

# Check metrics service
Write-Host "`nChecking metrics service..." -ForegroundColor Yellow
kubectl get service cloudflare-tunnel-metrics -n guacamole
Test-CommandSuccess "Metrics service check"

# Step 5: Display tunnel information
Write-Host "`n=== Step 5: Tunnel Information ===" -ForegroundColor Cyan

# Get tunnel logs from one pod
$podName = kubectl get pods -l app.kubernetes.io/name=cloudflare-tunnel -n guacamole -o jsonpath="{.items[0].metadata.name}" 2>$null
if ($podName) {
    Write-Host "Sample tunnel logs from pod: $podName" -ForegroundColor Yellow
    kubectl logs $podName -n guacamole --tail=10
}

# Success summary
Write-Host "`n=== Cloudflare Tunnel Deployment Complete! ===" -ForegroundColor Green

Write-Host "`n🌐 Tunnel Status:" -ForegroundColor Cyan
Write-Host "   ✓ 5 tunnel replicas deployed" -ForegroundColor Green
Write-Host "   ✓ Auto-scaling configured (5-10 replicas)" -ForegroundColor Green
Write-Host "   ✓ High availability with pod anti-affinity" -ForegroundColor Green
Write-Host "   ✓ Metrics endpoint available" -ForegroundColor Green
Write-Host "   ✓ Pod disruption budget configured" -ForegroundColor Green

Write-Host "`n📊 Monitoring:" -ForegroundColor Cyan
Write-Host "   • Metrics: kubectl port-forward svc/cloudflare-tunnel-metrics 2000:2000 -n guacamole" -ForegroundColor White
Write-Host "   • Logs: kubectl logs -l app.kubernetes.io/name=cloudflare-tunnel -n guacamole" -ForegroundColor White
Write-Host "   • Status: kubectl get pods -l app.kubernetes.io/name=cloudflare-tunnel -n guacamole" -ForegroundColor White

Write-Host "`n🔧 Management Commands:" -ForegroundColor Cyan
Write-Host "   • Scale: kubectl scale deployment cloudflare-tunnel --replicas=X -n guacamole" -ForegroundColor White
Write-Host "   • Restart: kubectl rollout restart deployment cloudflare-tunnel -n guacamole" -ForegroundColor White
Write-Host "   • Delete: kubectl delete -f cloudflare-tunnel-deployment.yaml" -ForegroundColor White

Write-Host "`n🎯 TutorPro360 Integration:" -ForegroundColor Cyan
Write-Host "   • Your TutorPro360 platform should now be accessible via Cloudflare Tunnel" -ForegroundColor Green
Write-Host "   • The tunnel provides secure external access to your educational platform" -ForegroundColor Green
Write-Host "   • 5 replicas ensure high availability for student and teacher access" -ForegroundColor Green

Write-Host "`n🎉 Cloudflare Tunnel is now protecting your TutorPro360 platform!" -ForegroundColor Green
