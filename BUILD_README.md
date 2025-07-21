# MLOps Lab - Build & Deploy Automation

This directory contains automation scripts for building and deploying the sentiment analysis ML API to Kubernetes.

## Quick Start

1. **Full deployment pipeline:**
   ```powershell
   .\build.ps1 full-deploy
   ```

2. **Test the deployed API:**
   ```powershell
   .\build.ps1 test
   ```

3. **Check deployment status:**
   ```powershell
   .\build.ps1 status
   ```

## Available Commands

### Build & Deploy
- `build` - Build Docker image
- `load` - Load image into Minikube  
- `deploy` - Apply Kubernetes manifests
- `full-deploy` - Complete build + load + deploy pipeline

### Testing & Access
- `test` - Test all API endpoints
- `port-forward` - Start port forwarding to access service locally
- `stop-port-forward` - Stop port forwarding

### Management
- `status` - Show deployment status (pods, services, deployments)
- `logs` - Show recent pod logs
- `restart` - Restart the deployment
- `clean` - Delete all Kubernetes resources

### Environment
- `minikube-start` - Start Minikube cluster
- `minikube-stop` - Stop Minikube cluster  
- `dev-setup` - Complete development environment setup

## Usage Examples

### Development Workflow
```powershell
# Set up everything from scratch
.\build.ps1 dev-setup

# Make code changes, then redeploy
.\build.ps1 redeploy

# Test your changes
.\build.ps1 test
```

### CI/CD Pipeline
```powershell
# Automated deployment
.\build.ps1 full-deploy

# Health check for CI/CD
.\build.ps1 health-check
```

### Troubleshooting
```powershell
# Check what's running
.\build.ps1 status

# View recent logs
.\build.ps1 logs

# Restart if needed
.\build.ps1 restart
```

## Requirements

- Docker Desktop
- Minikube with `mlops` profile
- kubectl configured
- PowerShell 5.0+

## Files

- `build.ps1` - Main PowerShell automation script
- `build.bat` - Windows batch wrapper (optional)
- `Makefile` - Cross-platform Makefile (if make is available)

## Configuration

The script uses these default settings:
- Image name: `sentiment-api:latest`
- Minikube profile: `mlops`
- Service name: `sentiment-api-service`
- Local port: `8080`

These can be modified in the variables section of `build.ps1`.
