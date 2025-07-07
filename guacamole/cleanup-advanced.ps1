#!/usr/bin/env powershell
# Advanced cleanup script for Guacamole deployment

param(
    [string]$Namespace = "guacamole",
    [switch]$Force = $false,
    [switch]$KeepPersistentVolumes = $false,
    [switch]$BackupBeforeCleanup = $true
)

Write-Host "=== Advanced Guacamole Cleanup ===" -ForegroundColor Yellow

# Warning
if (-not $Force) {
    Write-Host "`n⚠️  WARNING: This will delete all Guacamole resources!" -ForegroundColor Red
    Write-Host "This includes:" -ForegroundColor Red
    Write-Host "- All pods, services, and deployments" -ForegroundColor Red
    Write-Host "- ConfigMaps and Secrets" -ForegroundColor Red
    Write-Host "- Ingress resources" -ForegroundColor Red
    if (-not $KeepPersistentVolumes) {
        Write-Host "- Persistent Volumes and data" -ForegroundColor Red
    }
    Write-Host "- The entire '$Namespace' namespace" -ForegroundColor Red
    
    $confirmation = Read-Host "`nType 'DELETE' to confirm"
    if ($confirmation -ne "DELETE") {
        Write-Host "Cleanup cancelled by user" -ForegroundColor Green
        exit 0
    }
}

# Create backup before cleanup if requested
if ($BackupBeforeCleanup) {
    Write-Host "`nCreating backup before cleanup..." -ForegroundColor Yellow
    if (Test-Path "backup-database.ps1") {
        try {
            .\backup-database.ps1 -BackupPath "./cleanup-backups"
            Write-Host "✓ Backup created successfully" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Backup failed: $_" -ForegroundColor Yellow
            if (-not $Force) {
                $proceed = Read-Host "Continue cleanup without backup? (y/N)"
                if ($proceed -ne "y" -and $proceed -ne "Y") {
                    exit 1
                }
            }
        }
    } else {
        Write-Host "⚠️  Backup script not found, skipping backup" -ForegroundColor Yellow
    }
}

Write-Host "`nStarting cleanup process..." -ForegroundColor Yellow

# Function to safely delete resources
function Remove-ResourceSafely {
    param(
        [string]$ResourceType,
        [string]$ResourceName = "",
        [string]$Namespace = "guacamole"
    )
    
    try {
        if ($ResourceName) {
            kubectl delete $ResourceType $ResourceName -n $Namespace --ignore-not-found=true --timeout=60s
        } else {
            kubectl delete $ResourceType --all -n $Namespace --ignore-not-found=true --timeout=60s
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Deleted $ResourceType $(if($ResourceName) { $ResourceName } else { '(all)' })" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Failed to delete $ResourceType $(if($ResourceName) { $ResourceName } else { '(all)' })" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Error deleting $ResourceType`: $_" -ForegroundColor Yellow
    }
}

# Check if namespace exists
$namespaceExists = kubectl get namespace $Namespace 2>$null
if (-not $namespaceExists) {
    Write-Host "Namespace '$Namespace' does not exist. Nothing to clean up." -ForegroundColor Green
    exit 0
}

# Delete resources in order
Write-Host "`nDeleting application resources..." -ForegroundColor Cyan

# Stop deployments first
Write-Host "Scaling down deployments..." -ForegroundColor Yellow
kubectl scale deployment --all --replicas=0 -n $Namespace 2>$null

# Delete workloads
Remove-ResourceSafely "deployment" "" $Namespace
Remove-ResourceSafely "job" "" $Namespace
Remove-ResourceSafely "cronjob" "" $Namespace
Remove-ResourceSafely "statefulset" "" $Namespace
Remove-ResourceSafely "daemonset" "" $Namespace

# Delete autoscaling and policies
Remove-ResourceSafely "hpa" "" $Namespace
Remove-ResourceSafely "pdb" "" $Namespace
Remove-ResourceSafely "networkpolicy" "" $Namespace

# Wait for pods to terminate
Write-Host "Waiting for pods to terminate..." -ForegroundColor Yellow
kubectl wait --for=delete pod --all -n $Namespace --timeout=120s 2>$null

# Force delete any remaining pods
$remainingPods = kubectl get pods -n $Namespace --no-headers 2>$null
if ($remainingPods) {
    Write-Host "Force deleting remaining pods..." -ForegroundColor Yellow
    kubectl delete pod --all -n $Namespace --force --grace-period=0 2>$null
}

# Delete services and networking
Remove-ResourceSafely "service" "" $Namespace
Remove-ResourceSafely "ingress" "" $Namespace
Remove-ResourceSafely "endpoints" "" $Namespace

# Delete configuration
Remove-ResourceSafely "configmap" "" $Namespace
Remove-ResourceSafely "secret" "" $Namespace

# Handle persistent volumes
if (-not $KeepPersistentVolumes) {
    Write-Host "`nDeleting persistent storage..." -ForegroundColor Cyan
    Remove-ResourceSafely "pvc" "" $Namespace
    
    # Wait for PVCs to be deleted
    Start-Sleep -Seconds 5
    
    # Delete persistent volumes (cluster-scoped)
    Write-Host "Checking for associated persistent volumes..." -ForegroundColor Yellow
    $pvs = kubectl get pv -o json 2>$null | ConvertFrom-Json
    if ($pvs -and $pvs.items) {
        foreach ($pv in $pvs.items) {
            if ($pv.spec.claimRef -and $pv.spec.claimRef.namespace -eq $Namespace) {
                kubectl delete pv $pv.metadata.name --ignore-not-found=true
                Write-Host "✓ Deleted PV $($pv.metadata.name)" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "`nKeeping persistent volumes as requested" -ForegroundColor Yellow
    Write-Host "Note: PVCs will be deleted but PVs will remain" -ForegroundColor Yellow
    
    # Just delete PVCs
    Remove-ResourceSafely "pvc" "" $Namespace
}

# Delete any remaining resources
Write-Host "`nCleaning up any remaining resources..." -ForegroundColor Cyan
$allResources = kubectl api-resources --verbs=delete --namespaced -o name 2>$null
if ($allResources) {
    foreach ($resource in $allResources) {
        $items = kubectl get $resource -n $Namespace --no-headers 2>$null
        if ($items) {
            kubectl delete $resource --all -n $Namespace --ignore-not-found=true --timeout=30s 2>$null
        }
    }
}

# Delete the namespace
Write-Host "`nDeleting namespace..." -ForegroundColor Cyan
kubectl delete namespace $Namespace --ignore-not-found=true

# Wait for namespace deletion
Write-Host "Waiting for namespace deletion..." -ForegroundColor Yellow
$timeout = 120
$elapsed = 0
while ($elapsed -lt $timeout) {
    $namespaceStatus = kubectl get namespace $Namespace 2>$null
    if (-not $namespaceStatus) {
        break
    }
    Start-Sleep -Seconds 5
    $elapsed += 5
    Write-Host "." -NoNewline
}
Write-Host ""

# Verify cleanup
Write-Host "`nVerifying cleanup..." -ForegroundColor Yellow
$remainingNamespace = kubectl get namespace $Namespace 2>$null
if (-not $remainingNamespace) {
    Write-Host "✓ Cleanup completed successfully" -ForegroundColor Green
} else {
    Write-Host "⚠️  Namespace still exists, may be in terminating state" -ForegroundColor Yellow
    Write-Host "This is normal and the namespace will be deleted eventually" -ForegroundColor Yellow
    Write-Host "Check status with: kubectl get namespace $Namespace" -ForegroundColor Cyan
}

# Check for any remaining cluster-scoped resources
Write-Host "`nChecking for remaining cluster-scoped resources..." -ForegroundColor Yellow
$clusterRoles = kubectl get clusterrole | grep guacamole 2>$null
$clusterRoleBindings = kubectl get clusterrolebinding | grep guacamole 2>$null

if ($clusterRoles -or $clusterRoleBindings) {
    Write-Host "⚠️  Found cluster-scoped resources that may need manual cleanup:" -ForegroundColor Yellow
    if ($clusterRoles) { Write-Host "ClusterRoles: $clusterRoles" -ForegroundColor Cyan }
    if ($clusterRoleBindings) { Write-Host "ClusterRoleBindings: $clusterRoleBindings" -ForegroundColor Cyan }
}

Write-Host "`n=== Cleanup Summary ===" -ForegroundColor Green
Write-Host "Cleanup completed at: $(Get-Date)" -ForegroundColor White
Write-Host "Namespace: $Namespace" -ForegroundColor White
Write-Host "Persistent volumes kept: $KeepPersistentVolumes" -ForegroundColor White

if ($BackupBeforeCleanup -and (Test-Path "./cleanup-backups/")) {
    Write-Host "Backup location: ./cleanup-backups/" -ForegroundColor White
}

Write-Host "`nAll Guacamole resources have been removed." -ForegroundColor Green
Write-Host "You can now redeploy with: .\deploy.ps1" -ForegroundColor Cyan
