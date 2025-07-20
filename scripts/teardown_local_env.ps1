# Teardown local MLOps environment (PowerShell version)

Write-Host "=== MLOps Environment Teardown ===" -ForegroundColor Red
Write-Host "This script will remove Minikube, clean up containers, and optionally remove installed tools." -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Red

# Function to ask for confirmation
function Confirm-Action {
    param([string]$Message)
    do {
        $response = Read-Host "$Message [y/N]"
        if ($response -eq "" -or $response -match "^[Nn]") {
            return $false
        }
        if ($response -match "^[Yy]") {
            return $true
        }
        Write-Host "Please answer yes or no." -ForegroundColor Yellow
    } while ($true)
}

Write-Host "Starting teardown process..." -ForegroundColor Green

# 1. Stop and delete Minikube cluster
$minikubePath = Get-Command minikube -ErrorAction SilentlyContinue
if ($minikubePath) {
    Write-Host "Found Minikube installation" -ForegroundColor Cyan
    
    # Check if minikube is running
    try {
        minikube status 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Stopping Minikube cluster..." -ForegroundColor Yellow
            minikube stop
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Minikube cluster stopped successfully" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Warning: Failed to stop Minikube cluster" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Minikube cluster is not running" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Minikube cluster is not running" -ForegroundColor Cyan
    }
    
    # Delete the cluster
    Write-Host "Deleting Minikube cluster and all associated data..." -ForegroundColor Yellow
    minikube delete --all --purge
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Minikube cluster deleted successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Warning: Failed to delete Minikube cluster" -ForegroundColor Yellow
    }
    
    # Clean up minikube directory
    $minikubeDir = "$env:USERPROFILE\.minikube"
    if (Test-Path $minikubeDir) {
        Write-Host "Cleaning up Minikube configuration directory..." -ForegroundColor Yellow
        Remove-Item -Path $minikubeDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Minikube configuration directory removed" -ForegroundColor Green
    }
    
    # Ask if user wants to remove minikube binary (if installed via Chocolatey)
    if (Confirm-Action "Do you want to remove the Minikube binary?") {
        $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoPath) {
            Write-Host "Removing Minikube via Chocolatey..." -ForegroundColor Yellow
            choco uninstall minikube -y
            Write-Host "✅ Minikube removed via Chocolatey" -ForegroundColor Green
        } else {
            Write-Host "Chocolatey not found. Please remove Minikube manually." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Minikube not found, skipping..." -ForegroundColor Gray
}

# 2. Clean up Docker containers and images
$dockerPath = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerPath) {
    Write-Host "Found Docker installation" -ForegroundColor Cyan
    
    if (Confirm-Action "Do you want to clean up Docker containers and images created by Minikube?") {
        Write-Host "Cleaning up Docker containers..." -ForegroundColor Yellow
        
        # Stop and remove all containers
        try {
            $containers = docker ps -aq
            if ($containers) {
                docker stop $containers 2>$null
                docker rm $containers 2>$null
                Write-Host "✅ Docker containers cleaned up" -ForegroundColor Green
            } else {
                Write-Host "No Docker containers to clean up" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "No Docker containers to clean up" -ForegroundColor Cyan
        }
        
        # Remove Minikube-related images
        Write-Host "Removing Minikube-related Docker images..." -ForegroundColor Yellow
        try {
            $images = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern "(k8s|minikube|gcr\.io)"
            if ($images) {
                $images | ForEach-Object { docker rmi -f $_ 2>$null }
                Write-Host "✅ Minikube-related Docker images removed" -ForegroundColor Green
            } else {
                Write-Host "No Minikube-related Docker images found" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "No Minikube-related Docker images found" -ForegroundColor Cyan
        }
        
        if (Confirm-Action "Do you want to run docker system prune to remove all unused Docker resources?") {
            docker system prune -af --volumes
            Write-Host "✅ Docker system cleaned up" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Docker not found, skipping Docker cleanup..." -ForegroundColor Gray
}

# 3. Clean up kubectl configuration
Write-Host "Cleaning up kubectl configuration..." -ForegroundColor Yellow
$kubeConfigPath = "$env:USERPROFILE\.kube\config"
if (Test-Path $kubeConfigPath) {
    # Remove minikube context from kubectl config
    try {
        kubectl config delete-context minikube 2>$null
        kubectl config delete-cluster minikube 2>$null
        kubectl config delete-user minikube 2>$null
        Write-Host "✅ Minikube context removed from kubectl config" -ForegroundColor Green
    } catch {
        Write-Host "No Minikube context found in kubectl config" -ForegroundColor Cyan
    }
    
    if (Confirm-Action "Do you want to remove the entire kubectl configuration directory?") {
        Remove-Item -Path "$env:USERPROFILE\.kube" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ kubectl configuration directory removed" -ForegroundColor Green
    }
} else {
    Write-Host "kubectl configuration not found, skipping..." -ForegroundColor Gray
}

# 4. Optional: Remove installed tools
Write-Host ""
Write-Host "=== Optional Tool Removal ===" -ForegroundColor Magenta

$chocoPath = Get-Command choco -ErrorAction SilentlyContinue

# Remove kubectl
$kubectlPath = Get-Command kubectl -ErrorAction SilentlyContinue
if ($kubectlPath -and (Confirm-Action "Do you want to remove kubectl?")) {
    if ($chocoPath) {
        choco uninstall kubernetes-cli -y
        Write-Host "✅ kubectl removed via Chocolatey" -ForegroundColor Green
    } else {
        Write-Host "Chocolatey not found. Please remove kubectl manually." -ForegroundColor Yellow
    }
}

# Remove Helm
$helmPath = Get-Command helm -ErrorAction SilentlyContinue
if ($helmPath -and (Confirm-Action "Do you want to remove Helm?")) {
    if ($chocoPath) {
        choco uninstall kubernetes-helm -y
        Write-Host "✅ Helm removed via Chocolatey" -ForegroundColor Green
    } else {
        Write-Host "Chocolatey not found. Please remove Helm manually." -ForegroundColor Yellow
    }
    
    # Clean up Helm cache and config
    $helmCache = "$env:LOCALAPPDATA\helm"
    $helmConfig = "$env:APPDATA\helm"
    
    if (Test-Path $helmCache) {
        Remove-Item -Path $helmCache -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Helm cache removed" -ForegroundColor Green
    }
    
    if (Test-Path $helmConfig) {
        Remove-Item -Path $helmConfig -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Helm configuration removed" -ForegroundColor Green
    }
}

# 5. Clean up temporary files
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path "$scriptDir\get_helm.sh") {
    Remove-Item "$scriptDir\get_helm.sh" -Force -ErrorAction SilentlyContinue
}
Get-ChildItem -Path $scriptDir -Filter "minikube-*" | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Host "✅ Temporary files cleaned up" -ForegroundColor Green

# 6. Final verification
Write-Host ""
Write-Host "=== Teardown Summary ===" -ForegroundColor Magenta
Write-Host "Checking remaining components..." -ForegroundColor Yellow

$minikubePath = Get-Command minikube -ErrorAction SilentlyContinue
if (-not $minikubePath) {
    Write-Host "✅ Minikube: Not found (removed)" -ForegroundColor Green
} else {
    Write-Host "⚠️  Minikube: Still installed" -ForegroundColor Yellow
}

$kubectlPath = Get-Command kubectl -ErrorAction SilentlyContinue
if (-not $kubectlPath) {
    Write-Host "✅ kubectl: Not found (removed)" -ForegroundColor Green
} else {
    Write-Host "⚠️  kubectl: Still installed" -ForegroundColor Yellow
}

$helmPath = Get-Command helm -ErrorAction SilentlyContinue
if (-not $helmPath) {
    Write-Host "✅ Helm: Not found (removed)" -ForegroundColor Green
} else {
    Write-Host "⚠️  Helm: Still installed" -ForegroundColor Yellow
}

$dockerPath = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerPath) {
    try {
        $runningContainers = (docker ps -q).Count
        Write-Host "ℹ️  Docker: Still installed ($runningContainers containers running)" -ForegroundColor Cyan
    } catch {
        Write-Host "ℹ️  Docker: Still installed (unable to check containers)" -ForegroundColor Cyan
    }
} else {
    Write-Host "ℹ️  Docker: Not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Teardown Complete ===" -ForegroundColor Green
Write-Host "Your MLOps local environment has been torn down." -ForegroundColor Green
Write-Host ""
Write-Host "Note: Docker Desktop was not removed as it may be used by other applications." -ForegroundColor Yellow
Write-Host "If you want to remove Docker Desktop, please do so manually through:" -ForegroundColor Yellow
Write-Host "  - Windows: Settings > Apps > Docker Desktop" -ForegroundColor Yellow
Write-Host "  - Or: Add/Remove Programs" -ForegroundColor Yellow
Write-Host ""
Write-Host "To set up the environment again, run: .\setup_local_env.ps1" -ForegroundColor Cyan
