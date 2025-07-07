#!/usr/bin/env powershell
# Resource optimization script for Guacamole deployment

param(
    [string]$Environment = "production",  # production, staging, development
    [string]$Namespace = "guacamole"
)

Write-Host "=== Guacamole Resource Optimization ===" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Namespace: $Namespace" -ForegroundColor Cyan

# Define resource configurations for different environments
$resourceConfigs = @{
    "development" = @{
        "postgres" = @{
            "requests" = @{ "memory" = "256Mi"; "cpu" = "100m" }
            "limits" = @{ "memory" = "512Mi"; "cpu" = "500m" }
            "replicas" = 1
        }
        "guacamole" = @{
            "requests" = @{ "memory" = "512Mi"; "cpu" = "200m" }
            "limits" = @{ "memory" = "1Gi"; "cpu" = "1000m" }
            "replicas" = 1
        }
        "guacd" = @{
            "requests" = @{ "memory" = "128Mi"; "cpu" = "100m" }
            "limits" = @{ "memory" = "256Mi"; "cpu" = "500m" }
            "replicas" = 1
        }
    }
    "staging" = @{
        "postgres" = @{
            "requests" = @{ "memory" = "512Mi"; "cpu" = "250m" }
            "limits" = @{ "memory" = "1Gi"; "cpu" = "1000m" }
            "replicas" = 1
        }
        "guacamole" = @{
            "requests" = @{ "memory" = "1Gi"; "cpu" = "250m" }
            "limits" = @{ "memory" = "2Gi"; "cpu" = "1000m" }
            "replicas" = 2
        }
        "guacd" = @{
            "requests" = @{ "memory" = "256Mi"; "cpu" = "100m" }
            "limits" = @{ "memory" = "512Mi"; "cpu" = "500m" }
            "replicas" = 2
        }
    }
    "production" = @{
        "postgres" = @{
            "requests" = @{ "memory" = "1Gi"; "cpu" = "500m" }
            "limits" = @{ "memory" = "4Gi"; "cpu" = "2000m" }
            "replicas" = 1
        }
        "guacamole" = @{
            "requests" = @{ "memory" = "2Gi"; "cpu" = "500m" }
            "limits" = @{ "memory" = "4Gi"; "cpu" = "2000m" }
            "replicas" = 3
        }
        "guacd" = @{
            "requests" = @{ "memory" = "512Mi"; "cpu" = "200m" }
            "limits" = @{ "memory" = "1Gi"; "cpu" = "1000m" }
            "replicas" = 3
        }
    }
}

if (-not $resourceConfigs.ContainsKey($Environment)) {
    Write-Host "Error: Unknown environment '$Environment'. Valid options: development, staging, production" -ForegroundColor Red
    exit 1
}

$config = $resourceConfigs[$Environment]

Write-Host "`nApplying resource optimization for $Environment environment..." -ForegroundColor Yellow

# Function to update deployment resources
function Update-DeploymentResources {
    param(
        [string]$DeploymentName,
        [hashtable]$Resources,
        [int]$Replicas
    )
    
    Write-Host "`nUpdating $DeploymentName..." -ForegroundColor Yellow
    
    # Scale replicas
    kubectl scale deployment $DeploymentName -n $Namespace --replicas=$Replicas
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Scaled $DeploymentName to $Replicas replicas" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to scale $DeploymentName" -ForegroundColor Red
    }
    
    # Update resource requests and limits
    $requestsMemory = $Resources.requests.memory
    $requestsCpu = $Resources.requests.cpu
    $limitsMemory = $Resources.limits.memory
    $limitsCpu = $Resources.limits.cpu
    
    # Get the container name (assuming first container)
    $containerName = kubectl get deployment $DeploymentName -n $Namespace -o jsonpath="{.spec.template.spec.containers[0].name}"
    
    if ($containerName) {
        # Update resources
        kubectl patch deployment $DeploymentName -n $Namespace -p @"
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "$containerName",
            "resources": {
              "requests": {
                "memory": "$requestsMemory",
                "cpu": "$requestsCpu"
              },
              "limits": {
                "memory": "$limitsMemory",
                "cpu": "$limitsCpu"
              }
            }
          }
        ]
      }
    }
  }
}
"@
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Updated resources for $DeploymentName" -ForegroundColor Green
            Write-Host "  Requests: CPU=$requestsCpu, Memory=$requestsMemory" -ForegroundColor Cyan
            Write-Host "  Limits: CPU=$limitsCpu, Memory=$limitsMemory" -ForegroundColor Cyan
        } else {
            Write-Host "✗ Failed to update resources for $DeploymentName" -ForegroundColor Red
        }
    }
}

# Apply configurations
foreach ($component in $config.Keys) {
    $deploymentName = switch ($component) {
        "postgres" { "postgres" }
        "guacamole" { "guacamole" }
        "guacd" { "guacd" }
    }
    
    Update-DeploymentResources -DeploymentName $deploymentName -Resources $config[$component] -Replicas $config[$component].replicas
}

# Wait for rollout to complete
Write-Host "`nWaiting for deployments to rollout..." -ForegroundColor Yellow
foreach ($component in $config.Keys) {
    $deploymentName = switch ($component) {
        "postgres" { "postgres" }
        "guacamole" { "guacamole" }
        "guacd" { "guacd" }
    }
    
    Write-Host "Waiting for $deploymentName rollout..." -ForegroundColor Cyan
    kubectl rollout status deployment/$deploymentName -n $Namespace --timeout=300s
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $deploymentName rollout completed" -ForegroundColor Green
    } else {
        Write-Host "✗ $deploymentName rollout failed or timed out" -ForegroundColor Red
    }
}

# Show final status
Write-Host "`n=== Final Status ===" -ForegroundColor Green
kubectl get pods -n $Namespace -o wide
Write-Host "`nResource usage:" -ForegroundColor Cyan
kubectl top pods -n $Namespace 2>$null

Write-Host "`n=== Optimization Complete ===" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor White
Write-Host "All deployments have been optimized for the $Environment environment." -ForegroundColor White
Write-Host "`nTo monitor resource usage:" -ForegroundColor Yellow
Write-Host "  kubectl top pods -n $Namespace" -ForegroundColor Cyan
Write-Host "  kubectl get hpa -n $Namespace" -ForegroundColor Cyan
