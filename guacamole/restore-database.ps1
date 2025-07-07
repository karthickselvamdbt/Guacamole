#!/usr/bin/env powershell
# Database restore script for Guacamole PostgreSQL

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    [string]$Namespace = "guacamole",
    [switch]$Force = $false
)

Write-Host "=== Guacamole Database Restore ===" -ForegroundColor Green

# Validate backup file exists
if (-not (Test-Path $BackupFile)) {
    Write-Host "Error: Backup file not found: $BackupFile" -ForegroundColor Red
    exit 1
}

Write-Host "Backup file: $BackupFile" -ForegroundColor Cyan
Write-Host "Namespace: $Namespace" -ForegroundColor Cyan

# Check if backup file is compressed
$isCompressed = $false
$workingFile = $BackupFile

if ($BackupFile -match '\.(gz|zip)$') {
    $isCompressed = $true
    $workingFile = $BackupFile -replace '\.(gz|zip)$', ''
    
    Write-Host "`nDecompressing backup file..." -ForegroundColor Yellow
    
    if ($BackupFile.EndsWith('.gz')) {
        if (Get-Command gzip -ErrorAction SilentlyContinue) {
            gzip -d -c $BackupFile > $workingFile
        } else {
            Write-Host "Error: gzip not found. Please decompress manually." -ForegroundColor Red
            exit 1
        }
    } elseif ($BackupFile.EndsWith('.zip')) {
        Expand-Archive -Path $BackupFile -DestinationPath (Split-Path $workingFile) -Force
    }
    
    if (-not (Test-Path $workingFile)) {
        Write-Host "Error: Failed to decompress backup file" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Backup decompressed successfully" -ForegroundColor Green
}

# Check if PostgreSQL pod is running
$postgresPod = kubectl get pods -n $Namespace -l app.kubernetes.io/name=postgres -o jsonpath="{.items[0].metadata.name}" 2>$null

if (-not $postgresPod) {
    Write-Host "Error: PostgreSQL pod not found in namespace '$Namespace'" -ForegroundColor Red
    exit 1
}

Write-Host "Using PostgreSQL pod: $postgresPod" -ForegroundColor Cyan

# Warning about data loss
if (-not $Force) {
    Write-Host "`n⚠️  WARNING: This will replace all existing data in the database!" -ForegroundColor Red
    Write-Host "This action cannot be undone." -ForegroundColor Red
    $confirmation = Read-Host "Type 'YES' to continue"
    
    if ($confirmation -ne "YES") {
        Write-Host "Restore cancelled by user" -ForegroundColor Yellow
        exit 0
    }
}

# Create a backup of current database before restore
Write-Host "`nCreating safety backup of current database..." -ForegroundColor Yellow
$safetyBackupFile = "safety-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').sql"

try {
    kubectl exec -n $Namespace $postgresPod -- pg_dump -U postgres -d guacamole_db --no-password > $safetyBackupFile
    Write-Host "✓ Safety backup created: $safetyBackupFile" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not create safety backup: $_" -ForegroundColor Yellow
    if (-not $Force) {
        $proceed = Read-Host "Continue without safety backup? (y/N)"
        if ($proceed -ne "y" -and $proceed -ne "Y") {
            exit 1
        }
    }
}

# Stop Guacamole pods to prevent connections during restore
Write-Host "`nStopping Guacamole pods..." -ForegroundColor Yellow
kubectl scale deployment guacamole -n $Namespace --replicas=0
kubectl wait --for=delete pod -l app.kubernetes.io/name=guacamole -n $Namespace --timeout=60s

# Perform the restore
Write-Host "`nRestoring database from backup..." -ForegroundColor Yellow

try {
    # Drop existing database and recreate
    kubectl exec -n $Namespace $postgresPod -- psql -U postgres -c "DROP DATABASE IF EXISTS guacamole_db;"
    kubectl exec -n $Namespace $postgresPod -- psql -U postgres -c "CREATE DATABASE guacamole_db;"
    
    # Restore from backup
    Get-Content $workingFile | kubectl exec -i -n $Namespace $postgresPod -- psql -U postgres -d guacamole_db
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database restore completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "✗ Database restore failed!" -ForegroundColor Red
        
        # Attempt to restore from safety backup
        if (Test-Path $safetyBackupFile) {
            Write-Host "Attempting to restore from safety backup..." -ForegroundColor Yellow
            kubectl exec -n $Namespace $postgresPod -- psql -U postgres -c "DROP DATABASE IF EXISTS guacamole_db;"
            kubectl exec -n $Namespace $postgresPod -- psql -U postgres -c "CREATE DATABASE guacamole_db;"
            Get-Content $safetyBackupFile | kubectl exec -i -n $Namespace $postgresPod -- psql -U postgres -d guacamole_db
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Restored from safety backup" -ForegroundColor Green
            } else {
                Write-Host "✗ Safety backup restore also failed!" -ForegroundColor Red
            }
        }
        exit 1
    }
    
} catch {
    Write-Host "Error during restore: $_" -ForegroundColor Red
    exit 1
}

# Restart Guacamole pods
Write-Host "`nRestarting Guacamole pods..." -ForegroundColor Yellow
kubectl scale deployment guacamole -n $Namespace --replicas=2
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=guacamole -n $Namespace --timeout=300s

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Guacamole pods restarted successfully" -ForegroundColor Green
} else {
    Write-Host "⚠️  Guacamole pods may not have started properly" -ForegroundColor Yellow
    Write-Host "Check status with: kubectl get pods -n $Namespace" -ForegroundColor Cyan
}

# Cleanup temporary files
if ($isCompressed -and (Test-Path $workingFile) -and ($workingFile -ne $BackupFile)) {
    Remove-Item $workingFile -Force
    Write-Host "✓ Cleaned up temporary files" -ForegroundColor Green
}

# Verify restore
Write-Host "`nVerifying restore..." -ForegroundColor Yellow
$tableCount = kubectl exec -n $Namespace $postgresPod -- psql -U postgres -d guacamole_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>$null

if ($tableCount -and $tableCount.Trim() -gt 0) {
    Write-Host "✓ Database contains $($tableCount.Trim()) tables" -ForegroundColor Green
    
    # Check for admin user
    $adminExists = kubectl exec -n $Namespace $postgresPod -- psql -U postgres -d guacamole_db -t -c "SELECT COUNT(*) FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER';" 2>$null
    
    if ($adminExists -and $adminExists.Trim() -gt 0) {
        Write-Host "✓ Admin user exists in restored database" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Admin user not found in restored database" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Could not verify database contents" -ForegroundColor Yellow
}

Write-Host "`n=== Restore Summary ===" -ForegroundColor Green
Write-Host "Restore completed at: $(Get-Date)" -ForegroundColor White
Write-Host "Source backup: $BackupFile" -ForegroundColor White
Write-Host "PostgreSQL pod: $postgresPod" -ForegroundColor White
Write-Host "Namespace: $Namespace" -ForegroundColor White

if (Test-Path $safetyBackupFile) {
    Write-Host "Safety backup: $safetyBackupFile" -ForegroundColor White
    Write-Host "You can delete the safety backup if the restore was successful" -ForegroundColor Yellow
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Test Guacamole login and functionality" -ForegroundColor White
Write-Host "2. Verify all connections and users are restored" -ForegroundColor White
Write-Host "3. Run health check: .\health-check.ps1" -ForegroundColor White
