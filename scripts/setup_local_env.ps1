# Setup local environment for MLOps project (PowerShell version)

Write-Host "Setting up MLOps local environment..." -ForegroundColor Green

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "This script should be run as Administrator for best results."
}

# Check if WSL is enabled
$wslStatus = wsl --status 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "WSL is available" -ForegroundColor Green
} else {
    Write-Host "WSL not detected. Please enable WSL2 for better Minikube compatibility." -ForegroundColor Yellow
    Write-Host "Run: wsl --install" -ForegroundColor Yellow
}

# Check if Docker Desktop is installed
$dockerPath = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerPath) {
    Write-Host "Docker is installed: $($dockerPath.Source)" -ForegroundColor Green
    try {
        $dockerVersion = docker --version
        Write-Host "Docker version: $dockerVersion" -ForegroundColor Green
        
        # Check if Docker is running
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Docker is running" -ForegroundColor Green
        } else {
            Write-Host "Docker is installed but not running. Please start Docker Desktop." -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "Docker is installed but not accessible. Please check Docker Desktop." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Docker not found. Please install Docker Desktop." -ForegroundColor Red
    Write-Host "Download from: https://docs.docker.com/desktop/install/windows-install/" -ForegroundColor Yellow
    exit 1
}

# Check if Chocolatey is installed (for package management)
$chocoPath = Get-Command choco -ErrorAction SilentlyContinue
if (-not $chocoPath) {
    Write-Host "Chocolatey not found. Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Install Minikube
$minikubePath = Get-Command minikube -ErrorAction SilentlyContinue
if (-not $minikubePath) {
    Write-Host "Minikube not found. Installing via Chocolatey..." -ForegroundColor Yellow
    choco install minikube -y
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Verify installation
    $minikubePath = Get-Command minikube -ErrorAction SilentlyContinue
    if (-not $minikubePath) {
        Write-Host "Minikube installation failed. Please install manually." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Minikube is already installed: $($minikubePath.Source)" -ForegroundColor Green
}

# Install kubectl
$kubectlPath = Get-Command kubectl -ErrorAction SilentlyContinue
if (-not $kubectlPath) {
    Write-Host "kubectl not found. Installing via Chocolatey..." -ForegroundColor Yellow
    choco install kubernetes-cli -y
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "kubectl is already installed: $($kubectlPath.Source)" -ForegroundColor Green
}

# Install Helm
$helmPath = Get-Command helm -ErrorAction SilentlyContinue
if (-not $helmPath) {
    Write-Host "Helm not found. Installing via Chocolatey..." -ForegroundColor Yellow
    choco install kubernetes-helm -y
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "Helm is already installed: $($helmPath.Source)" -ForegroundColor Green
}

# Start Minikube
Write-Host "Starting Minikube..." -ForegroundColor Yellow
try {
    minikube start --driver=docker --cpus=4 --memory=8g
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Minikube started successfully" -ForegroundColor Green
    } else {
        Write-Host "Failed to start Minikube" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error starting Minikube: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Enable Minikube addons
Write-Host "Enabling Minikube addons..." -ForegroundColor Yellow
minikube addons enable ingress
minikube addons enable metrics-server

# Check Minikube status
Write-Host "Checking Minikube status..." -ForegroundColor Yellow
minikube status

# Check versions
Write-Host "`nInstalled versions:" -ForegroundColor Green
Write-Host "Docker: $(docker --version)" -ForegroundColor Cyan
Write-Host "Minikube: $(minikube version --short)" -ForegroundColor Cyan
Write-Host "kubectl: $(kubectl version --client --short)" -ForegroundColor Cyan
Write-Host "Helm: $(helm version --short)" -ForegroundColor Cyan

Write-Host "`nLocal environment setup complete!" -ForegroundColor Green
Write-Host "You can now use 'minikube dashboard' to open the Kubernetes dashboard" -ForegroundColor Yellow
