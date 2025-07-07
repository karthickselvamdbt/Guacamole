# SSH to cluster and get admin config
ssh kubernetes@10.0.7.161 "sudo cat /etc/kubernetes/admin.conf" > admin.conf
if ($LASTEXITCODE -eq 0) {
    Write-Host "Admin config saved to admin.conf" -ForegroundColor Green
    Write-Host "Test with: kubectl --kubeconfig=admin.conf get nodes" -ForegroundColor Cyan
} else {
    Write-Host "Failed to get admin config" -ForegroundColor Red
}
