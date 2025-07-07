# Test admin config
if (Test-Path "admin.conf") {
    Write-Host "Testing admin config..." -ForegroundColor Yellow
    kubectl --kubeconfig=admin.conf get nodes
    kubectl --kubeconfig=admin.conf cluster-info
} else {
    Write-Host "admin.conf not found. Run get-admin-config.ps1 first." -ForegroundColor Red
}
