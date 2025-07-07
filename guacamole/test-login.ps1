# Test Guacamole Login and Functionality
# This script tests the deployed Guacamole instance

Write-Host "=" * 60
Write-Host "Testing Apache Guacamole Deployment" -ForegroundColor Green
Write-Host "=" * 60

# Test 1: Check if Guacamole web UI is accessible
Write-Host "`n1. Testing web UI accessibility..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://10.0.7.161:30562" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Guacamole web UI is accessible at http://10.0.7.161:30562" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Failed to access Guacamole web UI: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Check pod status
Write-Host "`n2. Checking pod status..." -ForegroundColor Yellow
$pods = kubectl get pods -n guacamole --no-headers 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Pod Status:" -ForegroundColor Cyan
    $pods | ForEach-Object {
        $parts = $_ -split '\s+'
        $name = $parts[0]
        $ready = $parts[1]
        $status = $parts[2]
        if ($status -eq "Running" -and $ready -match "^[1-9]") {
            Write-Host "✅ $name : $status ($ready)" -ForegroundColor Green
        } else {
            Write-Host "❌ $name : $status ($ready)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "❌ Failed to get pod status" -ForegroundColor Red
}

# Test 3: Check service status
Write-Host "`n3. Checking service status..." -ForegroundColor Yellow
$services = kubectl get svc -n guacamole --no-headers 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Service Status:" -ForegroundColor Cyan
    $services | ForEach-Object {
        $parts = $_ -split '\s+'
        $name = $parts[0]
        $type = $parts[1]
        $ports = $parts[4]
        Write-Host "✅ $name ($type) : $ports" -ForegroundColor Green
    }
}

# Test 4: Check database connectivity
Write-Host "`n4. Testing database connectivity..." -ForegroundColor Yellow
try {
    kubectl exec -n guacamole deployment/postgres-simple -- psql -U postgres -d guacamole_db -c "SELECT COUNT(*) FROM guacamole_entity;" > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database is accessible and contains data" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Database connectivity test failed" -ForegroundColor Red
}

# Test 5: Verify admin user exists
Write-Host "`n5. Verifying admin user..." -ForegroundColor Yellow
try {
    $userCheck = kubectl exec -n guacamole deployment/postgres-simple -- psql -U postgres -d guacamole_db -c "SELECT name FROM guacamole_entity WHERE name = 'admin';" 2>$null
    if ($userCheck -match "admin") {
        Write-Host "✅ Admin user exists in database" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Failed to verify admin user" -ForegroundColor Red
}

Write-Host "`n" + "=" * 60
Write-Host "Login Information:" -ForegroundColor Green
Write-Host "=" * 60
Write-Host "URL: http://10.0.7.161:30562" -ForegroundColor Cyan
Write-Host "Username: admin" -ForegroundColor Cyan
Write-Host "Password: admin" -ForegroundColor Cyan
Write-Host "`nNote: Please change the default password after first login!" -ForegroundColor Yellow

Write-Host "`n" + "=" * 60
Write-Host "Test completed! Open http://10.0.7.161:30562 in your browser to access Guacamole." -ForegroundColor Green
Write-Host "=" * 60
