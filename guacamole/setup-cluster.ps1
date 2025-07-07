# Setup script for Ubuntu Kubernetes cluster at 10.0.7.161

Write-Host "Setting up kubectl for your Kubernetes cluster..." -ForegroundColor Green

$CLUSTER_IP = "10.0.7.161"
$CLUSTER_USER = "kubernetes"
$CLUSTER_PASSWORD = "root"

Write-Host "Configuring kubectl for cluster at $CLUSTER_IP..." -ForegroundColor Yellow

# Note: This assumes your cluster is using the default port 6443
# If your cluster uses a different port, update accordingly

try {
    # Check if we have a certificate file first
    $certFile = "cluster-ca.crt"
    if (Test-Path $certFile) {
        Write-Host "Using certificate file: $certFile" -ForegroundColor Green
        kubectl config set-cluster ubuntu-cluster --server="https://${CLUSTER_IP}:6443" --certificate-authority=$certFile
    } else {
        Write-Host "WARNING: No certificate file found. Using insecure connection for development only!" -ForegroundColor Yellow
        Write-Host "For production, obtain the cluster CA certificate and use --certificate-authority" -ForegroundColor Yellow
        kubectl config set-cluster ubuntu-cluster --server="https://${CLUSTER_IP}:6443" --insecure-skip-tls-verify=true
    }

    # Set user credentials
    kubectl config set-credentials $CLUSTER_USER --username=$CLUSTER_USER --password=$CLUSTER_PASSWORD

    # Set context
    kubectl config set-context ubuntu-context --cluster=ubuntu-cluster --user=$CLUSTER_USER

    # Use the context
    kubectl config use-context ubuntu-context
    
    Write-Host "kubectl configuration completed!" -ForegroundColor Green
    
    # Test the connection
    Write-Host "`nTesting connection..." -ForegroundColor Yellow
    kubectl get nodes
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nConnection successful! You can now deploy Guacamole." -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Cyan
        Write-Host "1. Run .\test-cluster.ps1 to verify cluster capabilities" -ForegroundColor White
        Write-Host "2. Update ingress.yaml with your desired domain name" -ForegroundColor White
        Write-Host "3. Run .\deploy.ps1 to deploy Guacamole" -ForegroundColor White
    } else {
        Write-Host "`nConnection failed. Please check:" -ForegroundColor Red
        Write-Host "- Cluster IP address: $CLUSTER_IP" -ForegroundColor Yellow
        Write-Host "- API server port (default: 6443)" -ForegroundColor Yellow
        Write-Host "- Username and password" -ForegroundColor Yellow
        Write-Host "- Network connectivity to the cluster" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error configuring kubectl: $_" -ForegroundColor Red
}

Write-Host "`nCurrent kubectl context:" -ForegroundColor Cyan
kubectl config current-context
