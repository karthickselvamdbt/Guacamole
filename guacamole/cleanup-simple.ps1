#!/usr/bin/env powershell
# Simple cleanup script for Apache Guacamole

param(
    [switch]$Force = $false
)

Write-Host "=== Apache Guacamole - Complete Cleanup ===" -ForegroundColor Yellow

# Warning and confirmation
if (-not $Force) {
    Write-Host "`n⚠️  WARNING: This will completely delete the Guacamole deployment!" -ForegroundColor Red
    Write-Host "This includes:" -ForegroundColor Red
    Write-Host "- All pods, services, and deployments" -ForegroundColor Red
    Write-Host "- All data and configurations" -ForegroundColor Red
    Write-Host "- The entire 'guacamole' namespace" -ForegroundColor Red
    
    $confirmation = Read-Host "`nType 'DELETE' to confirm complete cleanup"
    if ($confirmation -ne "DELETE") {
        Write-Host "Cleanup cancelled by user" -ForegroundColor Green
        exit 0
    }
}

# Check if namespace exists
$namespaceExists = kubectl get namespace guacamole 2>$null
if (-not $namespaceExists) {
    Write-Host "✓ No Guacamole deployment found. Nothing to clean up." -ForegroundColor Green
    exit 0
}

Write-Host "`nStarting cleanup..." -ForegroundColor Yellow

# Delete the namespace (this will delete everything inside it)
kubectl delete namespace guacamole --timeout=120s

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Namespace deletion initiated" -ForegroundColor Green
} else {
    Write-Host "✗ Namespace deletion failed" -ForegroundColor Red
    exit 1
}

# Wait for complete deletion
Write-Host "`nWaiting for complete cleanup..." -ForegroundColor Yellow
$timeout = 120
$elapsed = 0
while ($elapsed -lt $timeout) {
    $namespaceStatus = kubectl get namespace guacamole 2>$null
    if (-not $namespaceStatus) {
        Write-Host "`n✓ Cleanup completed successfully!" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 2
    $elapsed += 2
    Write-Host "." -NoNewline
}

if ($elapsed -ge $timeout) {
    Write-Host "`n⚠️  Cleanup is taking longer than expected but should complete soon." -ForegroundColor Yellow
    Write-Host "You can check status with: kubectl get namespace guacamole" -ForegroundColor Cyan
} else {
    Write-Host "`n🎉 All Guacamole resources have been completely removed!" -ForegroundColor Green
}

Write-Host "`nTo redeploy, run: .\deploy-clean.ps1" -ForegroundColor Cyan
