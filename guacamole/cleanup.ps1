# Cleanup script for Guacamole deployment

Write-Host "Removing Apache Guacamole deployment from Kubernetes..." -ForegroundColor Yellow

# Remove all resources in reverse order
Write-Host "Removing ingress..." -ForegroundColor Yellow
kubectl delete -f ingress.yaml --ignore-not-found=true

Write-Host "Removing monitoring configuration..." -ForegroundColor Yellow
kubectl delete -f monitoring-config.yaml --ignore-not-found=true

Write-Host "Removing security policies..." -ForegroundColor Yellow
kubectl delete -f security-policies.yaml --ignore-not-found=true

Write-Host "Removing autoscaling..." -ForegroundColor Yellow
kubectl delete -f horizontal-pod-autoscalers.yaml --ignore-not-found=true

Write-Host "Removing pod disruption budgets..." -ForegroundColor Yellow
kubectl delete -f pod-disruption-budgets.yaml --ignore-not-found=true

Write-Host "Removing Guacamole application..." -ForegroundColor Yellow
kubectl delete -f guacamole-deployment.yaml --ignore-not-found=true

Write-Host "Removing guacd daemon..." -ForegroundColor Yellow
kubectl delete -f guacd-deployment.yaml --ignore-not-found=true

Write-Host "Removing database initialization job..." -ForegroundColor Yellow
kubectl delete -f guacamole-db-init-job.yaml --ignore-not-found=true

Write-Host "Removing services..." -ForegroundColor Yellow
kubectl delete -f services.yaml --ignore-not-found=true

Write-Host "Removing PostgreSQL database..." -ForegroundColor Yellow
kubectl delete -f postgres-deployment.yaml --ignore-not-found=true

Write-Host "Removing persistent volumes..." -ForegroundColor Yellow
kubectl delete -f persistent-volumes.yaml --ignore-not-found=true

Write-Host "Removing configuration..." -ForegroundColor Yellow
kubectl delete -f configmaps.yaml --ignore-not-found=true

Write-Host "Removing secrets..." -ForegroundColor Yellow
kubectl delete -f secrets.yaml --ignore-not-found=true

Write-Host "Removing namespace..." -ForegroundColor Yellow
kubectl delete -f namespace.yaml --ignore-not-found=true

Write-Host ""
Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Persistent volumes may still exist depending on your storage class retention policy." -ForegroundColor Yellow
Write-Host "Check with: kubectl get pv | grep guacamole" -ForegroundColor Cyan
