#!/usr/bin/env powershell
# Database backup script for Guacamole PostgreSQL

param(
    [string]$BackupPath = "./backups",
    [string]$Namespace = "guacamole",
    [switch]$Compress = $true
)

Write-Host "=== Guacamole Database Backup ===" -ForegroundColor Green

# Create backup directory if it doesn't exist
if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    Write-Host "Created backup directory: $BackupPath" -ForegroundColor Yellow
}

# Generate backup filename with timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFile = "guacamole-backup-$timestamp.sql"
$backupFullPath = Join-Path $BackupPath $backupFile

Write-Host "`nStarting database backup..." -ForegroundColor Yellow
Write-Host "Backup file: $backupFullPath" -ForegroundColor Cyan

# Check if PostgreSQL pod is running
$postgresPod = kubectl get pods -n $Namespace -l app.kubernetes.io/name=postgres -o jsonpath="{.items[0].metadata.name}" 2>$null

if (-not $postgresPod) {
    Write-Host "Error: PostgreSQL pod not found in namespace '$Namespace'" -ForegroundColor Red
    exit 1
}

Write-Host "Using PostgreSQL pod: $postgresPod" -ForegroundColor Cyan

# Perform the backup
try {
    Write-Host "`nCreating database dump..." -ForegroundColor Yellow
    
    $backupCommand = "kubectl exec -n $Namespace $postgresPod -- pg_dump -U postgres -d guacamole_db --no-password"
    
    # Execute backup and save to file
    Invoke-Expression $backupCommand | Out-File -FilePath $backupFullPath -Encoding UTF8
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database backup completed successfully!" -ForegroundColor Green
        
        # Get file size
        $fileSize = (Get-Item $backupFullPath).Length
        $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
        Write-Host "Backup size: $fileSizeMB MB" -ForegroundColor Cyan
        
        # Compress if requested
        if ($Compress) {
            Write-Host "`nCompressing backup..." -ForegroundColor Yellow
            $compressedFile = "$backupFullPath.gz"
            
            # Use gzip if available, otherwise use PowerShell compression
            try {
                if (Get-Command gzip -ErrorAction SilentlyContinue) {
                    gzip $backupFullPath
                    $finalFile = $compressedFile
                } else {
                    # PowerShell compression
                    Compress-Archive -Path $backupFullPath -DestinationPath "$backupFullPath.zip" -Force
                    Remove-Item $backupFullPath -Force
                    $finalFile = "$backupFullPath.zip"
                }
                
                $compressedSize = (Get-Item $finalFile).Length
                $compressedSizeMB = [math]::Round($compressedSize / 1MB, 2)
                $compressionRatio = [math]::Round((1 - ($compressedSize / $fileSize)) * 100, 1)
                
                Write-Host "✓ Backup compressed successfully!" -ForegroundColor Green
                Write-Host "Compressed size: $compressedSizeMB MB (saved $compressionRatio%)" -ForegroundColor Cyan
                Write-Host "Final backup file: $finalFile" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Compression failed, keeping uncompressed backup" -ForegroundColor Yellow
                Write-Host "Final backup file: $backupFullPath" -ForegroundColor Green
            }
        } else {
            Write-Host "Final backup file: $backupFullPath" -ForegroundColor Green
        }
        
    } else {
        Write-Host "✗ Database backup failed!" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "Error during backup: $_" -ForegroundColor Red
    exit 1
}

# Cleanup old backups (keep last 7 days)
Write-Host "`nCleaning up old backups (keeping last 7 days)..." -ForegroundColor Yellow
$cutoffDate = (Get-Date).AddDays(-7)
$oldBackups = Get-ChildItem -Path $BackupPath -Filter "guacamole-backup-*" | Where-Object { $_.CreationTime -lt $cutoffDate }

if ($oldBackups) {
    foreach ($oldBackup in $oldBackups) {
        Remove-Item $oldBackup.FullName -Force
        Write-Host "Removed old backup: $($oldBackup.Name)" -ForegroundColor Gray
    }
    Write-Host "✓ Cleanup completed" -ForegroundColor Green
} else {
    Write-Host "No old backups to clean up" -ForegroundColor Gray
}

# Show backup summary
Write-Host "`n=== Backup Summary ===" -ForegroundColor Green
Write-Host "Backup completed at: $(Get-Date)" -ForegroundColor White
Write-Host "PostgreSQL pod: $postgresPod" -ForegroundColor White
Write-Host "Namespace: $Namespace" -ForegroundColor White

$allBackups = Get-ChildItem -Path $BackupPath -Filter "guacamole-backup-*" | Sort-Object CreationTime -Descending
Write-Host "`nAvailable backups:" -ForegroundColor Cyan
foreach ($backup in $allBackups) {
    $sizeMB = [math]::Round($backup.Length / 1MB, 2)
    Write-Host "  $($backup.Name) - $sizeMB MB - $($backup.CreationTime)" -ForegroundColor White
}

Write-Host "`nTo restore from this backup:" -ForegroundColor Yellow
Write-Host "  .\restore-database.ps1 -BackupFile `"$backupFullPath`"" -ForegroundColor Cyan
