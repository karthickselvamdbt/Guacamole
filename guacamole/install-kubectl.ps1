# Install kubectl on Windows
# This script will download and install kubectl

Write-Host "Installing kubectl for Windows..." -ForegroundColor Green

# Create kubectl directory if it doesn't exist
$kubectlDir = "$env:USERPROFILE\.kubectl"
if (!(Test-Path $kubectlDir)) {
    New-Item -ItemType Directory -Path $kubectlDir -Force
    Write-Host "Created directory: $kubectlDir" -ForegroundColor Yellow
}

# Download kubectl
Write-Host "Downloading kubectl..." -ForegroundColor Yellow
$kubectlUrl = "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"
$kubectlPath = "$kubectlDir\kubectl.exe"

try {
    Invoke-WebRequest -Uri $kubectlUrl -OutFile $kubectlPath
    Write-Host "kubectl downloaded successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to download kubectl: $_" -ForegroundColor Red
    exit 1
}

# Add to PATH for current session
$env:PATH += ";$kubectlDir"

# Add to PATH permanently
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$kubectlDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$kubectlDir", "User")
    Write-Host "Added kubectl to PATH permanently" -ForegroundColor Green
}

# Verify installation
Write-Host "`nVerifying kubectl installation..." -ForegroundColor Yellow
try {
    & "$kubectlPath" version --client
    Write-Host "`nkubectl installed successfully!" -ForegroundColor Green
    Write-Host "You can now run the cluster setup script." -ForegroundColor Cyan
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Close and reopen PowerShell (or restart VS Code terminal)" -ForegroundColor White
    Write-Host "2. Run: .\setup-cluster.ps1" -ForegroundColor White
    Write-Host "3. Run: .\test-cluster.ps1" -ForegroundColor White
    Write-Host "4. Run: .\deploy.ps1" -ForegroundColor White
} catch {
    Write-Host "Error verifying kubectl installation: $_" -ForegroundColor Red
}

Write-Host "`nAlternative: You can also use kubectl directly with the full path:" -ForegroundColor Cyan
Write-Host "$kubectlPath version --client" -ForegroundColor White
