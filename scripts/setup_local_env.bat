@echo off
echo MLOps Local Environment Setup
echo ==============================

echo.
echo This script will help you set up your local MLOps environment.
echo You can choose between different setup methods:
echo.
echo 1. PowerShell setup (recommended for Windows)
echo 2. WSL/Bash setup (if you prefer using WSL)
echo 3. Manual setup instructions
echo.

choice /c 123 /m "Choose setup method"

if errorlevel 3 goto manual
if errorlevel 2 goto wsl
if errorlevel 1 goto powershell

:powershell
echo Running PowerShell setup...
powershell -ExecutionPolicy Bypass -File "%~dp0setup_local_env.ps1"
goto end

:wsl
echo Running WSL/Bash setup...
echo Note: Make sure WSL is installed and you have a Linux distribution set up.
wsl bash "%~dp0setup_local_env.sh"
goto end

:manual
echo Manual Setup Instructions:
echo ==========================
echo.
echo 1. Install Docker Desktop:
echo    - Download from: https://docs.docker.com/desktop/install/windows-install/
echo    - Make sure to enable WSL2 integration
echo.
echo 2. Install Minikube:
echo    - Download from: https://minikube.sigs.k8s.io/docs/start/
echo    - Or use: choco install minikube
echo.
echo 3. Install kubectl:
echo    - Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
echo    - Or use: choco install kubernetes-cli
echo.
echo 4. Install Helm:
echo    - Download from: https://helm.sh/docs/intro/install/
echo    - Or use: choco install kubernetes-helm
echo.
echo 5. Start Minikube:
echo    - Run: minikube start --driver=docker --cpus=4 --memory=8g
echo.
echo 6. Enable addons:
echo    - Run: minikube addons enable ingress
echo    - Run: minikube addons enable metrics-server
echo.

:end
echo.
echo Setup process completed. Check the output above for any errors.
pause
