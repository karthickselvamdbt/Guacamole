# Pre-deployment setup for Guacamole on Kubernetes
# This script installs required components before deploying Guacamole

Write-Host "=== Pre-deployment Setup ===" -ForegroundColor Green

# Install NGINX Ingress Controller
Write-Host "`nInstalling NGINX Ingress Controller..." -ForegroundColor Yellow
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml

Write-Host "Waiting for ingress controller to be ready..." -ForegroundColor Cyan
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s

# Check ingress controller status
Write-Host "`nChecking ingress controller status..." -ForegroundColor Yellow
kubectl get pods -n ingress-nginx

# Create local storage class for the cluster
Write-Host "`nCreating local storage class..." -ForegroundColor Yellow
$storageClass = @"
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: false
reclaimPolicy: Delete
"@

$storageClass | kubectl apply -f -

# Check storage class
Write-Host "`nChecking storage classes..." -ForegroundColor Yellow
kubectl get storageclass

Write-Host "`n=== Pre-deployment Complete ===" -ForegroundColor Green
Write-Host "Your cluster now has:" -ForegroundColor Cyan
Write-Host "✓ NGINX Ingress Controller" -ForegroundColor White
Write-Host "✓ Local storage class" -ForegroundColor White
Write-Host "`nYou can now run the Guacamole deployment with:" -ForegroundColor Yellow
Write-Host ".\deploy.ps1" -ForegroundColor White
