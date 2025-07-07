#!/usr/bin/env powershell
# Generate secure secrets for Guacamole deployment

Write-Host "=== Guacamole Secrets Generator ===" -ForegroundColor Green

# Function to generate random password
function Generate-SecurePassword {
    param(
        [int]$Length = 16
    )
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    $password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $password
}

# Function to encode to base64
function ConvertTo-Base64 {
    param([string]$Text)
    return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Text))
}

Write-Host "`nGenerating secure passwords..." -ForegroundColor Yellow

# Generate passwords
$postgresPassword = Generate-SecurePassword -Length 20
$guacamolePassword = Generate-SecurePassword -Length 16

# Fixed values
$postgresUser = "postgres"
$postgresDb = "guacamole_db"
$guacamoleUser = "guacadmin"

Write-Host "`nGenerated credentials:" -ForegroundColor Cyan
Write-Host "PostgreSQL User: $postgresUser" -ForegroundColor White
Write-Host "PostgreSQL Password: $postgresPassword" -ForegroundColor White
Write-Host "PostgreSQL Database: $postgresDb" -ForegroundColor White
Write-Host "Guacamole User: $guacamoleUser" -ForegroundColor White
Write-Host "Guacamole Password: $guacamolePassword" -ForegroundColor White

# Encode to base64
$postgresPasswordB64 = ConvertTo-Base64 -Text $postgresPassword
$postgresUserB64 = ConvertTo-Base64 -Text $postgresUser
$postgresDbB64 = ConvertTo-Base64 -Text $postgresDb
$guacamoleUserB64 = ConvertTo-Base64 -Text $guacamoleUser
$guacamolePasswordB64 = ConvertTo-Base64 -Text $guacamolePassword

# Create new secrets file
$secretsContent = @"
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: guacamole
  labels:
    app.kubernetes.io/name: postgres
    app.kubernetes.io/instance: postgres
    app.kubernetes.io/component: database
type: Opaque
data:
  postgres-password: $postgresPasswordB64
  postgres-user: $postgresUserB64
  postgres-db: $postgresDbB64
---
apiVersion: v1
kind: Secret
metadata:
  name: guacamole-secret
  namespace: guacamole
  labels:
    app.kubernetes.io/name: guacamole
    app.kubernetes.io/instance: guacamole
    app.kubernetes.io/component: web-app
type: Opaque
data:
  guacamole-user: $guacamoleUserB64
  guacamole-password: $guacamolePasswordB64
"@

# Backup existing secrets file
if (Test-Path "secrets.yaml") {
    Copy-Item "secrets.yaml" "secrets.yaml.backup"
    Write-Host "`nBacked up existing secrets.yaml to secrets.yaml.backup" -ForegroundColor Yellow
}

# Write new secrets file
$secretsContent | Out-File -FilePath "secrets-new.yaml" -Encoding UTF8

Write-Host "`nNew secrets file created: secrets-new.yaml" -ForegroundColor Green
Write-Host "`nTo apply the new secrets:" -ForegroundColor Cyan
Write-Host "1. Review the generated secrets-new.yaml file" -ForegroundColor White
Write-Host "2. Replace secrets.yaml with secrets-new.yaml if satisfied" -ForegroundColor White
Write-Host "3. Run: kubectl apply -f secrets.yaml" -ForegroundColor White

Write-Host "`n⚠️  IMPORTANT: Save these credentials securely!" -ForegroundColor Red
Write-Host "PostgreSQL: $postgresUser / $postgresPassword" -ForegroundColor Yellow
Write-Host "Guacamole: $guacamoleUser / $guacamolePassword" -ForegroundColor Yellow
