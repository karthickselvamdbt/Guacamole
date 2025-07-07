#!/usr/bin/env powershell
# Comprehensive health check script for Guacamole deployment

param(
    [string]$Namespace = "guacamole",
    [switch]$Detailed = $false,
    [switch]$Continuous = $false,
    [int]$Interval = 30
)

Write-Host "=== Guacamole Health Check ===" -ForegroundColor Green

# Function to check component health
function Test-ComponentHealth {
    param(
        [string]$ComponentName,
        [string]$LabelSelector
    )
    
    Write-Host "`n--- $ComponentName Health ---" -ForegroundColor Cyan
    
    # Get pods
    $pods = kubectl get pods -n $Namespace -l $LabelSelector -o json | ConvertFrom-Json
    
    if (-not $pods.items) {
        Write-Host "✗ No pods found for $ComponentName" -ForegroundColor Red
        return $false
    }
    
    $healthyPods = 0
    $totalPods = $pods.items.Count
    
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        $podStatus = $pod.status.phase
        $ready = $true
        
        # Check container readiness
        if ($pod.status.containerStatuses) {
            foreach ($container in $pod.status.containerStatuses) {
                if (-not $container.ready) {
                    $ready = $false
                    break
                }
            }
        }
        
        if ($podStatus -eq "Running" -and $ready) {
            Write-Host "✓ $podName - Running and Ready" -ForegroundColor Green
            $healthyPods++
        } else {
            Write-Host "✗ $podName - $podStatus (Ready: $ready)" -ForegroundColor Red
            
            if ($Detailed) {
                # Show recent events for this pod
                Write-Host "  Recent events:" -ForegroundColor Yellow
                kubectl get events -n $Namespace --field-selector involvedObject.name=$podName --sort-by='.lastTimestamp' | Select-Object -Last 3
            }
        }
    }
    
    $healthPercentage = [math]::Round(($healthyPods / $totalPods) * 100, 1)
    Write-Host "Health: $healthyPods/$totalPods pods healthy ($healthPercentage%)" -ForegroundColor $(if ($healthyPods -eq $totalPods) { "Green" } else { "Yellow" })
    
    return ($healthyPods -eq $totalPods)
}

# Function to test service connectivity
function Test-ServiceConnectivity {
    param([string]$ServiceName, [int]$Port)
    
    try {
        # Create a temporary test pod to check connectivity
        $testPod = "health-test-$(Get-Random)"
        kubectl run $testPod --image=busybox:1.35 --rm -it --restart=Never -n $Namespace --timeout=30s -- /bin/sh -c "nc -z $ServiceName $Port" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ $ServiceName`:$Port - Accessible" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ $ServiceName`:$Port - Not accessible" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ $ServiceName`:$Port - Test failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check resource usage
function Test-ResourceUsage {
    Write-Host "`n--- Resource Usage ---" -ForegroundColor Cyan
    
    try {
        $resourceOutput = kubectl top pods -n $Namespace 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host $resourceOutput
            Write-Host "✓ Resource metrics available" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Resource metrics not available (metrics-server may not be installed)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Could not retrieve resource usage" -ForegroundColor Yellow
    }
}

# Function to perform full health check
function Invoke-HealthCheck {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "`n=== Health Check at $timestamp ===" -ForegroundColor Green
    
    $overallHealth = $true
    
    # Check each component
    $components = @(
        @{ Name = "PostgreSQL"; Selector = "app.kubernetes.io/name=postgres" }
        @{ Name = "Guacd"; Selector = "app.kubernetes.io/name=guacd" }
        @{ Name = "Guacamole"; Selector = "app.kubernetes.io/name=guacamole" }
    )
    
    foreach ($component in $components) {
        $componentHealth = Test-ComponentHealth -ComponentName $component.Name -LabelSelector $component.Selector
        $overallHealth = $overallHealth -and $componentHealth
    }
    
    # Check services
    Write-Host "`n--- Service Connectivity ---" -ForegroundColor Cyan
    $services = @(
        @{ Name = "postgres-service"; Port = 5432 }
        @{ Name = "guacd-service"; Port = 4822 }
        @{ Name = "guacamole-service"; Port = 80 }
    )
    
    foreach ($service in $services) {
        $serviceHealth = Test-ServiceConnectivity -ServiceName $service.Name -Port $service.Port
        $overallHealth = $overallHealth -and $serviceHealth
    }
    
    # Check persistent volumes
    Write-Host "`n--- Storage Health ---" -ForegroundColor Cyan
    $pvcs = kubectl get pvc -n $Namespace -o json | ConvertFrom-Json
    
    if ($pvcs.items) {
        foreach ($pvc in $pvcs.items) {
            $pvcName = $pvc.metadata.name
            $pvcStatus = $pvc.status.phase
            
            if ($pvcStatus -eq "Bound") {
                Write-Host "✓ PVC $pvcName - Bound" -ForegroundColor Green
            } else {
                Write-Host "✗ PVC $pvcName - $pvcStatus" -ForegroundColor Red
                $overallHealth = $false
            }
        }
    } else {
        Write-Host "⚠️  No PVCs found" -ForegroundColor Yellow
    }
    
    # Check ingress
    Write-Host "`n--- Ingress Health ---" -ForegroundColor Cyan
    $ingresses = kubectl get ingress -n $Namespace -o json | ConvertFrom-Json
    
    if ($ingresses.items) {
        foreach ($ingress in $ingresses.items) {
            $ingressName = $ingress.metadata.name
            $hosts = $ingress.spec.rules | ForEach-Object { $_.host }
            
            Write-Host "✓ Ingress $ingressName - Configured for: $($hosts -join ', ')" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️  No ingress resources found" -ForegroundColor Yellow
    }
    
    # Resource usage
    if ($Detailed) {
        Test-ResourceUsage
    }
    
    # Overall status
    Write-Host "`n--- Overall Health ---" -ForegroundColor Cyan
    if ($overallHealth) {
        Write-Host "✓ All systems healthy" -ForegroundColor Green
    } else {
        Write-Host "✗ Some issues detected" -ForegroundColor Red
    }
    
    return $overallHealth
}

# Main execution
if ($Continuous) {
    Write-Host "Starting continuous health monitoring (interval: $Interval seconds)" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    
    while ($true) {
        Invoke-HealthCheck
        Start-Sleep -Seconds $Interval
        Clear-Host
    }
} else {
    $healthy = Invoke-HealthCheck
    
    if ($healthy) {
        Write-Host "`n🎉 Guacamole deployment is healthy!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n⚠️  Issues detected in Guacamole deployment" -ForegroundColor Yellow
        Write-Host "Run with -Detailed flag for more information" -ForegroundColor Cyan
        Write-Host "Or run troubleshooting: .\troubleshoot-deployment.ps1" -ForegroundColor Cyan
        exit 1
    }
}
