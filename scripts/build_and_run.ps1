Write-Host "Building and Running ML Service" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Set working directory to project root
Set-Location "$PSScriptRoot\.."

# Step 1: Train the model
Write-Host "Step 1: Training the model..." -ForegroundColor Yellow
Set-Location "models"
python train_model.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "Model training failed!" -ForegroundColor Red
    exit 1
}
Set-Location ".."

# Step 2: Build Docker image
Write-Host ""
Write-Host "Step 2: Building Docker image..." -ForegroundColor Yellow
docker build -t mlapp:latest .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed!" -ForegroundColor Red
    exit 1
}

# Step 3: Run the container
Write-Host ""
Write-Host "Step 3: Running the container..." -ForegroundColor Yellow
Write-Host "Stopping any existing container..."
docker stop mlapp-container 2>$null
docker rm mlapp-container 2>$null

Write-Host "Starting new container..."
docker run -d --name mlapp-container -p 8000:8000 mlapp:latest

if ($LASTEXITCODE -eq 0) {
    Write-Host "Container started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "API is now available at:" -ForegroundColor Cyan
    Write-Host "   http://localhost:8000"
    Write-Host "   http://localhost:8000/docs (Swagger UI)"
    Write-Host ""
    Write-Host "Waiting for service to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Test if service is ready
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8000/healthz" -Method Get -TimeoutSec 10
        Write-Host "Service is healthy and ready!" -ForegroundColor Green
    } catch {
        Write-Host "Service starting up... check logs if issues persist" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "To test the API, run:" -ForegroundColor Yellow
    Write-Host "   cd app; python test_api.py"
    Write-Host ""
    Write-Host "To view logs:" -ForegroundColor Yellow
    Write-Host "   docker logs -f mlapp-container"
    Write-Host ""
    Write-Host "To stop the container:" -ForegroundColor Yellow
    Write-Host "   docker stop mlapp-container"
} else {
    Write-Host "Failed to start container!" -ForegroundColor Red
    exit 1
}
