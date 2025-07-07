# Deploy all Guacamole components

Write-Host "=== Deploying Apache Guacamole to Kubernetes ===" -ForegroundColor Green

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

# Check if namespace already exists
$namespaceExists = kubectl get namespace guacamole 2>$null
if ($namespaceExists) {
    Write-Host "⚠️  Namespace 'guacamole' already exists. Continuing with deployment..." -ForegroundColor Yellow
}

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

# Deploy database
Write-Host "`nDeploying PostgreSQL database..." -ForegroundColor Yellow
kubectl apply -f postgres-deployment.yaml
Test-CommandSuccess "PostgreSQL deployment"

kubectl apply -f services.yaml
Test-CommandSuccess "Services creation"

# Wait for PostgreSQL to be ready
Write-Host "`nWaiting for PostgreSQL to be ready (timeout: 5 minutes)..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgres -n guacamole --timeout=300s

if (-not (Test-CommandSuccess "PostgreSQL readiness")) {
    Write-Host "PostgreSQL deployment failed or timed out" -ForegroundColor Red
    Write-Host "Troubleshooting commands:" -ForegroundColor Yellow
    Write-Host "  kubectl get pods -n guacamole" -ForegroundColor Cyan
    Write-Host "  kubectl logs -n guacamole deployment/postgres" -ForegroundColor Cyan
    Write-Host "  kubectl describe pod -n guacamole -l app.kubernetes.io/name=postgres" -ForegroundColor Cyan
    exit 1
}

Write-Host "✓ PostgreSQL is ready!" -ForegroundColor Green

# Initialize database schema
Write-Host "Initializing Guacamole database schema..." -ForegroundColor Yellow
kubectl apply -f guacamole-db-init-job.yaml

# Wait for database initialization to complete
Write-Host "Waiting for database initialization to complete..." -ForegroundColor Yellow
kubectl wait --for=condition=complete job/guacamole-db-init -n guacamole --timeout=300s

if ($LASTEXITCODE -ne 0) {
    Write-Host "Database initialization failed. Check logs with: kubectl logs job/guacamole-db-init -n guacamole" -ForegroundColor Red
    exit 1
}

# Deploy guacd daemon
Write-Host "Deploying guacd daemon..." -ForegroundColor Yellow
kubectl apply -f guacd-deployment.yaml

# Deploy Guacamole web application
Write-Host "Deploying Guacamole web application..." -ForegroundColor Yellow
kubectl apply -f guacamole-deployment.yaml

# Apply production features
Write-Host "Applying production features..." -ForegroundColor Yellow
kubectl apply -f pod-disruption-budgets.yaml
kubectl apply -f horizontal-pod-autoscalers.yaml
kubectl apply -f security-policies.yaml

# Note about ingress
Write-Host ""
Write-Host "IMPORTANT: Before applying ingress, update the domain name in ingress.yaml" -ForegroundColor Red
Write-Host "Current placeholder: guacamole.yourdomain.com" -ForegroundColor Red
Write-Host ""
Write-Host "To apply ingress after updating the domain:"
Write-Host "kubectl apply -f ingress.yaml" -ForegroundColor Cyan
Write-Host ""

# Apply monitoring configuration
Write-Host "Applying monitoring configuration..." -ForegroundColor Yellow
kubectl apply -f monitoring-config.yaml

Write-Host ""
Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Check deployment status:" -ForegroundColor Cyan
Write-Host "kubectl get pods -n guacamole" -ForegroundColor White
Write-Host "kubectl get svc -n guacamole" -ForegroundColor White
Write-Host ""
Write-Host "Default login credentials:" -ForegroundColor Cyan
Write-Host "Username: guacadmin" -ForegroundColor White
Write-Host "Password: guacadmin123" -ForegroundColor White
Write-Host ""
Write-Host "SECURITY WARNING: Change the default password immediately after first login!" -ForegroundColor Red
