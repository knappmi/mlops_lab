# MLOps Lab - PowerShell Build Script
# Automates build, deploy, and management tasks for the sentiment analysis API

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

# Variables
$IMAGE_NAME = "sentiment-api"
$IMAGE_TAG = "latest"
$MINIKUBE_PROFILE = "mlops"
$NAMESPACE = "default"
$SERVICE_NAME = "sentiment-api-service"
$PORT = "8080"

function Show-Help {
    Write-Host "MLOps Lab - Available Commands:"
    Write-Host ""
    Write-Host "Build & Deploy:"
    Write-Host "  .\build.ps1 build           - Build Docker image"
    Write-Host "  .\build.ps1 load            - Load image into Minikube"
    Write-Host "  .\build.ps1 deploy          - Apply Kubernetes manifests"
    Write-Host "  .\build.ps1 full-deploy     - Build + Load + Deploy (complete pipeline)"
    Write-Host ""
    Write-Host "Testing & Access:"
    Write-Host "  .\build.ps1 test            - Test all API endpoints"
    Write-Host "  .\build.ps1 port-forward    - Start port forwarding to access service"
    Write-Host "  .\build.ps1 stop-port-forward - Stop port forwarding"
    Write-Host ""
    Write-Host "Management:"
    Write-Host "  .\build.ps1 status          - Show deployment status"
    Write-Host "  .\build.ps1 logs            - Show pod logs"
    Write-Host "  .\build.ps1 restart         - Restart deployment"
    Write-Host "  .\build.ps1 clean           - Delete all resources"
    Write-Host ""
    Write-Host "Environment:"
    Write-Host "  .\build.ps1 minikube-start  - Start Minikube cluster"
    Write-Host "  .\build.ps1 minikube-stop   - Stop Minikube cluster"
    Write-Host "  .\build.ps1 dev-setup       - Complete dev environment setup"
}

function Build-Image {
    Write-Host "Building Docker image..."
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Image built successfully"
    } else {
        Write-Host "Build failed" -ForegroundColor Red
        exit 1
    }
}

function Load-Image {
    Write-Host "Loading image into Minikube..."
    minikube image load "${IMAGE_NAME}:${IMAGE_TAG}" --profile=$MINIKUBE_PROFILE
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Image loaded into Minikube"
    } else {
        Write-Host "Load failed" -ForegroundColor Red
        exit 1
    }
}

function Deploy-App {
    Write-Host "Deploying to Kubernetes..."
    kubectl apply -f k8s/
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Waiting for deployment to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/$IMAGE_NAME
        Write-Host "Deployment successful"
    } else {
        Write-Host "Deploy failed" -ForegroundColor Red
        exit 1
    }
}

function Full-Deploy {
    Build-Image
    Load-Image
    Deploy-App
    Write-Host "Full deployment completed!"
    Show-Status
}

function Test-API {
    Write-Host "Testing API endpoints..."
    Write-Host "Testing health endpoint..."
    
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:$PORT/healthz" -Method Get -TimeoutSec 5
        Write-Host "Health check: $($health.status)"
    } catch {
        Write-Host "Health check failed - make sure port-forward is running" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)"
    }
    
    Write-Host "Testing prediction endpoint..."
    try {
        $body = @{text="This is amazing!"} | ConvertTo-Json
        $result = Invoke-RestMethod -Uri "http://localhost:$PORT/predict" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 5
        Write-Host "Prediction: '$($result.text)' -> $($result.sentiment) ($([math]::Round($result.confidence * 100, 2))%)"
    } catch {
        Write-Host "Prediction test failed - make sure port-forward is running" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)"
    }
}

function Start-PortForward {
    Write-Host "Starting port forwarding on port $PORT..."
    
    # Kill any existing port-forward processes
    Get-Process -Name "kubectl" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*port-forward*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Start new port-forward in background
    Start-Job -ScriptBlock {
        param($serviceName, $port)
        kubectl port-forward service/$serviceName "${port}:80"
    } -ArgumentList $SERVICE_NAME, $PORT | Out-Null
    
    Start-Sleep 3  # Give it time to start
    Write-Host "Port forwarding started. Access API at http://localhost:$PORT"
    Write-Host "Use '.\build.ps1 stop-port-forward' to stop"
}

function Stop-PortForward {
    Write-Host "Stopping port forwarding..."
    Get-Process -Name "kubectl" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*port-forward*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
    Write-Host "Port forwarding stopped"
}

function Show-Status {
    Write-Host "=== Deployment Status ==="
    Write-Host "Pods:"
    kubectl get pods -l app=$IMAGE_NAME
    Write-Host ""
    Write-Host "Services:"
    kubectl get svc $SERVICE_NAME
    Write-Host ""
    Write-Host "Deployments:"
    kubectl get deployment $IMAGE_NAME
}

function Show-Logs {
    Write-Host "=== Pod Logs ==="
    kubectl logs -l app=$IMAGE_NAME --tail=20 --prefix=true
}

function Restart-Deployment {
    Write-Host "Restarting deployment..."
    kubectl rollout restart deployment/$IMAGE_NAME
    kubectl rollout status deployment/$IMAGE_NAME
    Write-Host "Deployment restarted"
}

function Clean-Resources {
    $confirmation = Read-Host "This will delete all Kubernetes resources. Continue? [y/N]"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        Write-Host "Cleaning up Kubernetes resources..."
        kubectl delete -f k8s/ --ignore-not-found=true
        Write-Host "Resources cleaned up"
    } else {
        Write-Host "Cleanup cancelled"
    }
}

function Start-Minikube {
    Write-Host "Starting Minikube cluster..."
    minikube start --profile=$MINIKUBE_PROFILE --driver=docker --cpus=4 --memory=6g
    kubectl config use-context $MINIKUBE_PROFILE
    Write-Host "Minikube started and configured"
}

function Stop-Minikube {
    Write-Host "Stopping Minikube cluster..."
    minikube stop --profile=$MINIKUBE_PROFILE
    Write-Host "Minikube stopped"
}

function Setup-DevEnvironment {
    Start-Minikube
    Full-Deploy
    Start-PortForward
    Write-Host "Development environment ready!"
    Write-Host "API available at: http://localhost:$PORT"
}

function Quick-Redeploy {
    Build-Image
    Load-Image
    Restart-Deployment
    Write-Host "Quick redeploy completed!"
}

function Health-Check {
    Write-Host "Performing health check..."
    
    # Check if pods are running
    $pods = kubectl get pods -l app=$IMAGE_NAME --no-headers 2>$null
    if ($pods -match "Running") {
        Write-Host "Pods are running"
    } else {
        Write-Host "Pods not running" -ForegroundColor Red
        exit 1
    }
    
    # Check API health
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:$PORT/healthz" -Method Get -TimeoutSec 5
        Write-Host "API is healthy"
    } catch {
        Write-Host "API health check failed" -ForegroundColor Red
        exit 1
    }
}

# Main command dispatcher
switch ($Command.ToLower()) {
    "help" { Show-Help }
    "build" { Build-Image }
    "load" { Load-Image }
    "deploy" { Deploy-App }
    "full-deploy" { Full-Deploy }
    "test" { Test-API }
    "port-forward" { Start-PortForward }
    "stop-port-forward" { Stop-PortForward }
    "status" { Show-Status }
    "logs" { Show-Logs }
    "restart" { Restart-Deployment }
    "clean" { Clean-Resources }
    "minikube-start" { Start-Minikube }
    "minikube-stop" { Stop-Minikube }
    "dev-setup" { Setup-DevEnvironment }
    "redeploy" { Quick-Redeploy }
    "health-check" { Health-Check }
    default { 
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Show-Help 
    }
}
