# mlops_lab
Repo for ML OPS pipeline development

## Quick Start

### Local Environment Setup

This project includes scripts to set up your local development environment with Minikube, Docker, kubectl, and Helm.

#### Windows Users (Recommended)

Run the interactive setup batch file:
```cmd
scripts\setup_local_env.bat
```

Or run the PowerShell script directly:
```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup_local_env.ps1
```

#### WSL/Linux Users

```bash
chmod +x scripts/setup_local_env.sh
./scripts/setup_local_env.sh
```

### Troubleshooting

If you encounter issues during setup, check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide for common problems and solutions.

## Prerequisites

- Windows 10/11 with WSL2 (for WSL setup) or Windows with Docker Desktop
- At least 8GB RAM (4GB will be allocated to Minikube)
- Docker Desktop installed and running
- Internet connection for downloading components

## What Gets Installed

The setup scripts will install/configure:
- Minikube (Kubernetes cluster)
- Docker (if not already installed)
- kubectl (Kubernetes CLI)
- Helm (Kubernetes package manager)
- Required Minikube addons (ingress, metrics-server)

## Environment Teardown

When you're done with development or want to clean up your system, use the teardown scripts:

### Windows Users (Recommended)

Run the interactive teardown batch file:
```cmd
scripts\teardown_local_env.bat
```

Or run the PowerShell script directly:
```powershell
powershell -ExecutionPolicy Bypass -File scripts\teardown_local_env.ps1
```

### WSL/Linux Users

```bash
chmod +x scripts/teardown_local_env.sh
./scripts/teardown_local_env.sh
```

### What Gets Removed

The teardown scripts will:
- Stop and delete the Minikube cluster
- Clean up Docker containers and images created by Minikube
- Remove kubectl contexts and configurations
- Optionally remove installed binaries (minikube, kubectl, helm)
- Clean up cache and configuration directories

**Note:** Docker Desktop itself is not removed as it may be used by other applications.
