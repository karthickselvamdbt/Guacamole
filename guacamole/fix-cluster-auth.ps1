# Get proper kubeconfig from Kubernetes cluster
# This script helps you connect to your Kubernetes cluster

Write-Host "=== Kubernetes Configuration Helper ===" -ForegroundColor Green

$CLUSTER_IP = "10.0.7.161"
$USERNAME = "kubernetes"
$PASSWORD = "root"

Write-Host "`nCluster Information:" -ForegroundColor Yellow
Write-Host "IP: $CLUSTER_IP" -ForegroundColor White
Write-Host "Username: $USERNAME" -ForegroundColor White

Write-Host "`nThe cluster is rejecting basic authentication." -ForegroundColor Red
Write-Host "Modern Kubernetes clusters typically use certificate-based authentication." -ForegroundColor Yellow

Write-Host "`nTo fix this, you need to:" -ForegroundColor Green

Write-Host "`n1. SSH to your cluster and get the admin config:" -ForegroundColor Cyan
Write-Host "   ssh $USERNAME@$CLUSTER_IP" -ForegroundColor White
Write-Host "   sudo cat /etc/kubernetes/admin.conf" -ForegroundColor White

Write-Host "`n2. Copy the content to a local file (e.g., admin.conf)" -ForegroundColor Cyan

Write-Host "`n3. Use the admin config with kubectl:" -ForegroundColor Cyan
Write-Host "   kubectl --kubeconfig=admin.conf get nodes" -ForegroundColor White

Write-Host "`n4. Or set it as your default config:" -ForegroundColor Cyan
Write-Host "   Copy-Item admin.conf `$env:USERPROFILE\.kube\config" -ForegroundColor White

Write-Host "`nAlternatively, if your cluster supports it:" -ForegroundColor Green
Write-Host "1. Check if basic auth is enabled in the API server" -ForegroundColor White
Write-Host "2. Create a service account with proper RBAC permissions" -ForegroundColor White
Write-Host "3. Use token-based authentication" -ForegroundColor White

Write-Host "`nWould you like me to create scripts to help with these options? (Y/N)" -ForegroundColor Yellow
$response = Read-Host

if ($response -eq "Y" -or $response -eq "y") {
    Write-Host "`nCreating helper scripts..." -ForegroundColor Green
    
    # Create SSH helper script
    $sshScript = @"
# SSH to cluster and get admin config
ssh $USERNAME@$CLUSTER_IP "sudo cat /etc/kubernetes/admin.conf" > admin.conf
if (`$LASTEXITCODE -eq 0) {
    Write-Host "Admin config saved to admin.conf" -ForegroundColor Green
    Write-Host "Test with: kubectl --kubeconfig=admin.conf get nodes" -ForegroundColor Cyan
} else {
    Write-Host "Failed to get admin config" -ForegroundColor Red
}
"@
    $sshScript | Out-File -FilePath "get-admin-config.ps1" -Encoding UTF8
    
    # Create test script for admin config
    $testScript = @"
# Test admin config
if (Test-Path "admin.conf") {
    Write-Host "Testing admin config..." -ForegroundColor Yellow
    kubectl --kubeconfig=admin.conf get nodes
    kubectl --kubeconfig=admin.conf cluster-info
} else {
    Write-Host "admin.conf not found. Run get-admin-config.ps1 first." -ForegroundColor Red
}
"@
    $testScript | Out-File -FilePath "test-admin-config.ps1" -Encoding UTF8
    
    Write-Host "Created scripts:" -ForegroundColor Green
    Write-Host "- get-admin-config.ps1 (get config from cluster)" -ForegroundColor White
    Write-Host "- test-admin-config.ps1 (test the admin config)" -ForegroundColor White
}
