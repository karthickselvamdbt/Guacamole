#!/usr/bin/env powershell
# Build script for TutorPro360 Guacamole Extension

Write-Host "=== Building TutorPro360 Guacamole Extension ===" -ForegroundColor Green

# Check if Java is available for jar command
try {
    $javaVersion = java -version 2>&1
    Write-Host "✓ Java found: $($javaVersion[0])" -ForegroundColor Green
} catch {
    Write-Host "✗ Java not found. Please install Java to build the extension." -ForegroundColor Red
    exit 1
}

# Set paths
$extensionDir = "tutorpro360-extension"
$outputJar = "tutorpro360-branding.jar"

# Check if extension directory exists
if (-not (Test-Path $extensionDir)) {
    Write-Host "✗ Extension directory not found: $extensionDir" -ForegroundColor Red
    exit 1
}

Write-Host "Building extension from: $extensionDir" -ForegroundColor Yellow

# Change to extension directory
Push-Location $extensionDir

try {
    # Create the JAR file
    Write-Host "Creating JAR file..." -ForegroundColor Yellow

    # Use jar command to create the extension
    jar -cf "../$outputJar" *

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Extension built successfully: $outputJar" -ForegroundColor Green

        # Get file size
        $jarFile = Get-Item "../$outputJar"
        $fileSize = [math]::Round($jarFile.Length / 1KB, 2)
        Write-Host "✓ File size: $fileSize KB" -ForegroundColor Green

        # List contents
        Write-Host "`nExtension contents:" -ForegroundColor Cyan
        jar -tf "../$outputJar"

    } else {
        Write-Host "✗ Failed to build extension" -ForegroundColor Red
        exit 1
    }

} finally {
    # Return to original directory
    Pop-Location
}

Write-Host "`n=== Build Complete ===" -ForegroundColor Green
Write-Host "Extension file: $outputJar" -ForegroundColor Cyan
Write-Host "`nTo install:" -ForegroundColor Yellow
Write-Host "1. Copy $outputJar to your Guacamole extensions directory" -ForegroundColor White
Write-Host "2. Restart Guacamole services" -ForegroundColor White
Write-Host "3. Clear browser cache and reload" -ForegroundColor White

Write-Host "`nExtension directories by OS:" -ForegroundColor Yellow
Write-Host "• RHEL/CentOS: /var/lib/guacamole/extensions/" -ForegroundColor White
Write-Host "• Debian/Ubuntu: /etc/guacamole/extensions/" -ForegroundColor White
Write-Host "• Docker: Mount to /etc/guacamole/extensions/" -ForegroundColor White