# Get admin config with password handling
Write-Host "Attempting to get admin config from cluster..." -ForegroundColor Yellow
Write-Host "You will be prompted for the SSH password and then the sudo password." -ForegroundColor Cyan

# Use SSH with password prompt and sudo with stdin
$command = "echo 'root' | sudo -S cat /etc/kubernetes/admin.conf"
ssh kubernetes@10.0.7.161 $command > admin.conf

if ($LASTEXITCODE -eq 0) {
    Write-Host "Admin config saved to admin.conf" -ForegroundColor Green
    Write-Host "File size: $((Get-Item admin.conf).Length) bytes" -ForegroundColor Cyan
    
    # Check if file has content
    if ((Get-Item admin.conf).Length -gt 0) {
        Write-Host "Testing admin config..." -ForegroundColor Yellow
        kubectl --kubeconfig=admin.conf get nodes
    } else {
        Write-Host "Admin config file is empty. Check permissions." -ForegroundColor Red
    }
} else {
    Write-Host "Failed to get admin config. Exit code: $LASTEXITCODE" -ForegroundColor Red
}
