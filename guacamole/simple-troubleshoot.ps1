# Simple Kubernetes cluster troubleshooting

Write-Host "=== Kubernetes Cluster Troubleshooting ===" -ForegroundColor Green

$CLUSTER_IP = "10.0.7.161"

# Test basic connectivity
Write-Host "`nTesting connectivity to $CLUSTER_IP..." -ForegroundColor Yellow
$connection = Test-NetConnection -ComputerName $CLUSTER_IP -Port 6443 -WarningAction SilentlyContinue
if ($connection.TcpTestSucceeded) {
    Write-Host "✓ Port 6443 is reachable" -ForegroundColor Green
} else {
    Write-Host "✗ Cannot reach port 6443" -ForegroundColor Red
}

# Check current kubectl config
Write-Host "`nCurrent kubectl configuration:" -ForegroundColor Yellow
kubectl config view --minify

# Test kubectl commands
Write-Host "`nTesting kubectl commands..." -ForegroundColor Yellow

Write-Host "Testing 'kubectl version --client':" -ForegroundColor Cyan
kubectl version --client

Write-Host "`nTesting 'kubectl get nodes':" -ForegroundColor Cyan
kubectl get nodes

Write-Host "`nTesting 'kubectl cluster-info':" -ForegroundColor Cyan  
kubectl cluster-info

Write-Host "`n=== Diagnosis ===" -ForegroundColor Green
Write-Host "If you see 'Forbidden' or authentication errors, the cluster might require:" -ForegroundColor Yellow
Write-Host "1. Client certificates instead of basic auth" -ForegroundColor White
Write-Host "2. Token-based authentication" -ForegroundColor White
Write-Host "3. Proper RBAC configuration" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Check if the cluster supports basic authentication" -ForegroundColor White
Write-Host "2. Get the proper kubeconfig from the cluster admin" -ForegroundColor White
Write-Host "3. SSH to the cluster and copy /etc/kubernetes/admin.conf" -ForegroundColor White
