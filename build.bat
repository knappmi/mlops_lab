@echo off
REM MLOps Lab - Batch Build Script
REM Simple wrapper around the PowerShell script

if "%1"=="" (
    powershell -ExecutionPolicy Bypass -File build.ps1 help
) else (
    powershell -ExecutionPolicy Bypass -File build.ps1 %1
)
