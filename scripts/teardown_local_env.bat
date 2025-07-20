@echo off
echo MLOps Local Environment Teardown
echo =================================

echo.
echo WARNING: This will remove your MLOps development environment including:
echo - Minikube cluster and all associated data
echo - Docker containers and images created by Minikube
echo - kubectl and Helm configurations
echo - Optionally: kubectl, Helm, and Minikube binaries
echo.

choice /c YN /m "Are you sure you want to continue with the teardown"
if errorlevel 2 goto cancel
if errorlevel 1 goto proceed

:proceed
echo.
echo Choose teardown method:
echo.
echo 1. PowerShell teardown (recommended for Windows)
echo 2. WSL/Bash teardown (if you set up using WSL)
echo 3. Cancel
echo.

choice /c 123 /m "Choose teardown method"

if errorlevel 3 goto cancel
if errorlevel 2 goto wsl
if errorlevel 1 goto powershell

:powershell
echo Running PowerShell teardown...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0teardown_local_env.ps1"
goto end

:wsl
echo Running WSL/Bash teardown...
echo Note: Make sure WSL is available and you have the necessary permissions.
echo.
wsl bash "%~dp0teardown_local_env.sh"
goto end

:cancel
echo.
echo Teardown cancelled by user.
echo Your MLOps environment remains intact.
goto end

:end
echo.
echo Teardown process completed. Check the output above for any errors.
pause
