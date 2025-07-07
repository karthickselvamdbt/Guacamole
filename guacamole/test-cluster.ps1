# Kubernetes Cluster Connection Test
# Run this script to verify connection to your cluster

Write-Host "Testing connection to Kubernetes cluster..." -ForegroundColor Green

# Test basic cluster connectivity
Write-Host "`nChecking cluster info..." -ForegroundColor Yellow
kubectl cluster-info

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to connect to cluster. Please check your kubeconfig." -ForegroundColor Red
    Write-Host "`nTo configure kubectl for your cluster at 10.0.7.161:" -ForegroundColor Cyan
    Write-Host "kubectl config set-cluster my-cluster --server=https://10.0.7.161:6443" -ForegroundColor White
    Write-Host "kubectl config set-credentials kubernetes --username=kubernetes --password=root" -ForegroundColor White
    Write-Host "kubectl config set-context my-context --cluster=my-cluster --user=kubernetes" -ForegroundColor White
    Write-Host "kubectl config use-context my-context" -ForegroundColor White
    exit 1
}

Write-Host "`nChecking nodes..." -ForegroundColor Yellow
kubectl get nodes

Write-Host "`nChecking namespaces..." -ForegroundColor Yellow
kubectl get namespaces

Write-Host "`nChecking storage classes..." -ForegroundColor Yellow
kubectl get storageclass

Write-Host "`nChecking if ingress controller is installed..." -ForegroundColor Yellow
kubectl get pods -A | Select-String -Pattern "ingress|nginx"

Write-Host "`nCluster connectivity test completed!" -ForegroundColor Green
Write-Host "`nYour cluster appears to be ready for Guacamole deployment." -ForegroundColor Cyan
