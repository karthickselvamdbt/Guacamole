#!/usr/bin/env powershell
# Troubleshoot Kubernetes cluster connection

Write-Host "=== Kubernetes Cluster Troubleshooting ===" -ForegroundColor Green

$CLUSTER_IP = "10.0.7.161"
$API_PORT = "6443"

# Test network connectivity
Write-Host "`nTesting network connectivity..." -ForegroundColor Yellow
$connection = Test-NetConnection -ComputerName $CLUSTER_IP -Port $API_PORT -WarningAction SilentlyContinue
if ($connection.TcpTestSucceeded) {
    Write-Host "✓ Network connectivity to $CLUSTER_IP`:$API_PORT successful" -ForegroundColor Green
} else {
    Write-Host "✗ Cannot reach $CLUSTER_IP`:$API_PORT" -ForegroundColor Red
    exit 1
}

# Check if cluster is using different port
Write-Host "`nChecking common Kubernetes ports..." -ForegroundColor Yellow
$ports = @(6443, 8443, 443)
foreach ($port in $ports) {
    $test = Test-NetConnection -ComputerName $CLUSTER_IP -Port $port -WarningAction SilentlyContinue
    if ($test.TcpTestSucceeded) {
        Write-Host "✓ Port $port is open" -ForegroundColor Green
    } else {
        Write-Host "✗ Port $port is closed" -ForegroundColor Red
    }
}

# Try to check the API server directly
Write-Host "`nTesting HTTPS endpoints..." -ForegroundColor Yellow
$endpoints = @(
    "https://$CLUSTER_IP`:6443/version",
    "https://$CLUSTER_IP`:6443/api/v1",
    "https://$CLUSTER_IP`:6443/"
)

foreach ($endpoint in $endpoints) {
    try {
        Write-Host "Testing $endpoint..." -ForegroundColor Cyan
        # Skip certificate validation for testing
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        $response = Invoke-WebRequest -Uri $endpoint -Method GET -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        Write-Host "✓ $endpoint responded with status $($response.StatusCode)" -ForegroundColor Green
        if ($endpoint -like "*/version") {
            Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "✓ $endpoint requires authentication (401) - API server is running" -ForegroundColor Yellow
        } elseif ($statusCode -eq 403) {
            Write-Host "✓ $endpoint returned 403 - API server is running but access denied" -ForegroundColor Yellow
        } else {
            Write-Host "✗ $endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Check kubectl configuration
Write-Host "`nCurrent kubectl configuration:" -ForegroundColor Yellow
kubectl config view --minify

# Try different authentication methods
Write-Host "`nTrying different authentication approaches..." -ForegroundColor Yellow

# Method 1: Basic auth (current)
Write-Host "Method 1: Basic authentication with username/password" -ForegroundColor Cyan
kubectl get nodes --v=2

# Method 2: Try without TLS verification
Write-Host "`nMethod 2: Testing cluster connection details" -ForegroundColor Cyan
kubectl cluster-info --v=2

Write-Host "`n=== Troubleshooting Complete ===" -ForegroundColor Green
Write-Host "`nIf the API server is responding but authentication fails, you may need:" -ForegroundColor Yellow
Write-Host "1. Valid client certificates instead of username/password" -ForegroundColor White
Write-Host "2. A service account token" -ForegroundColor White
Write-Host "3. To check if basic auth is enabled on the cluster" -ForegroundColor White
Write-Host "4. To verify the cluster is properly configured for external access" -ForegroundColor White

Write-Host "`nTo get cluster access, you might need to:" -ForegroundColor Yellow
Write-Host "1. SSH to the cluster node and copy /etc/kubernetes/admin.conf" -ForegroundColor White
Write-Host "2. Use 'kubectl config view --raw' on the cluster to get the full config" -ForegroundColor White
Write-Host "3. Configure the cluster to accept basic authentication" -ForegroundColor White
