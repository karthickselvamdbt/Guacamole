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

# Test version endpoint
try {
    Write-Host "Testing https://$CLUSTER_IP`:6443/version..." -ForegroundColor Cyan
    Add-Type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    $response = Invoke-WebRequest -Uri "https://$CLUSTER_IP`:6443/version" -Method GET -TimeoutSec 10 -UseBasicParsing
    Write-Host "✓ API server responded with status $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "✓ API server requires authentication (401) - server is running" -ForegroundColor Yellow
    } elseif ($statusCode -eq 403) {
        Write-Host "✓ API server returned 403 - server is running but access denied" -ForegroundColor Yellow
    } else {
        Write-Host "✗ API server test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Check kubectl configuration
Write-Host "`nCurrent kubectl configuration:" -ForegroundColor Yellow
kubectl config view --minify

# Try different authentication methods
Write-Host "`nTrying kubectl authentication..." -ForegroundColor Yellow

# Method 1: Basic auth (current)
Write-Host "Method 1: Basic authentication with username/password" -ForegroundColor Cyan
try {
    kubectl get nodes --request-timeout=10s
} catch {
    Write-Host "Basic auth failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Method 2: Try cluster info
Write-Host "`nMethod 2: Testing cluster info" -ForegroundColor Cyan
try {
    kubectl cluster-info --request-timeout=10s
} catch {
    Write-Host "Cluster info failed: $($_.Exception.Message)" -ForegroundColor Red
}

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
