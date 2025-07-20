# Troubleshooting Guide for MLOps Local Environment Setup

## Common WSL/Minikube Issues and Solutions

### Issue 1: "WSL 2 installation is incomplete"
**Solution:**
1. Enable WSL feature:
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-for-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```
2. Restart your computer
3. Download and install the WSL2 Linux kernel update package
4. Set WSL 2 as default: `wsl --set-default-version 2`

### Issue 2: "Docker is not running" or "Cannot connect to the Docker daemon"
**Solution:**
1. Install Docker Desktop for Windows
2. Enable WSL2 integration in Docker Desktop settings
3. Start Docker Desktop and wait for it to fully initialize
4. Verify: `docker --version` and `docker info`

### Issue 3: "minikube start" fails with driver issues
**Solution:**
Try these drivers in order:
```bash
# Option 1: Docker driver (recommended)
minikube start --driver=docker --cpus=4 --memory=8g

# Option 2: If Docker fails, try Hyper-V (requires admin)
minikube start --driver=hyperv --cpus=4 --memory=8g

# Option 3: VirtualBox (if installed)
minikube start --driver=virtualbox --cpus=4 --memory=8g
```

### Issue 4: "Insufficient memory" errors
**Solution:**
1. Close unnecessary applications
2. Reduce Minikube memory allocation:
   ```bash
   minikube start --driver=docker --cpus=2 --memory=4g
   ```
3. For WSL, increase WSL memory limit in `.wslconfig`:
   ```
   [wsl2]
   memory=8GB
   processors=4
   ```

### Issue 5: "kubectl: command not found" after Minikube installation
**Solution:**
```bash
# Use Minikube's kubectl
minikube kubectl -- get pods

# Or install kubectl separately
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Issue 6: Permission denied errors in WSL
**Solution:**
```bash
# Fix common permission issues
sudo chown -R $(whoami) ~/.minikube
sudo chmod -R u+rwx ~/.minikube

# For Docker socket issues
sudo usermod -aG docker $USER
newgrp docker
```

### Issue 7: "VT-x/AMD-v virtualization must be enabled" on WSL
**Solution:**
1. Enable virtualization in BIOS/UEFI
2. Use the `--no-vtx-check` flag:
   ```bash
   minikube start --driver=docker --no-vtx-check --cpus=2 --memory=4g
   ```

### Issue 8: Slow performance or high CPU usage
**Solution:**
1. Reduce resource allocation:
   ```bash
   minikube delete
   minikube start --driver=docker --cpus=2 --memory=4g
   ```
2. Disable unnecessary addons:
   ```bash
   minikube addons list
   minikube addons disable <addon-name>
   ```

### Issue 9: Network connectivity issues
**Solution:**
```bash
# Check Minikube IP
minikube ip

# Test connectivity
minikube ssh
ping google.com
exit

# Reset network settings
minikube stop
minikube delete
minikube start --driver=docker
```

### Issue 10: "Error response from daemon: conflict" when using Docker driver
**Solution:**
```bash
# Clean up Docker resources
docker system prune -a
minikube delete
minikube start --driver=docker
```

## Verification Commands

After setup, run these commands to verify everything is working:

```bash
# Check versions
docker --version
minikube version
kubectl version --client
helm version

# Check cluster status
minikube status
kubectl get nodes
kubectl get pods --all-namespaces

# Test deployment
kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4
kubectl expose deployment hello-minikube --type=NodePort --port=8080
minikube service hello-minikube --url
```

## Getting Help

If you continue to have issues:

1. Check Minikube logs: `minikube logs`
2. Check system events: `minikube logs --follow`
3. Reset everything: `minikube delete && minikube start`
4. Check the official documentation:
   - [Minikube Troubleshooting](https://minikube.sigs.k8s.io/docs/handbook/troubleshooting/)
   - [Docker Desktop WSL2 Guide](https://docs.docker.com/desktop/wsl/)
   - [WSL Troubleshooting](https://docs.microsoft.com/en-us/windows/wsl/troubleshooting)

## Performance Tips

- Use Docker Desktop with WSL2 integration for best performance
- Allocate appropriate resources based on your system specs
- Consider using a local Docker registry for faster image pulls
- Enable resource monitoring: `minikube addons enable metrics-server`

## Environment Teardown

### Automated Teardown

The project includes automated teardown scripts to cleanly remove all components:

**Windows (Interactive):**
```cmd
scripts\teardown_local_env.bat
```

**PowerShell:**
```powershell
powershell -ExecutionPolicy Bypass -File scripts\teardown_local_env.ps1
```

**WSL/Linux:**
```bash
chmod +x scripts/teardown_local_env.sh
./scripts/teardown_local_env.sh
```

### Manual Teardown Steps

If the automated scripts don't work, you can manually tear down the environment:

1. **Stop and Delete Minikube:**
   ```bash
   minikube stop
   minikube delete --all --purge
   rm -rf ~/.minikube
   ```

2. **Clean Docker Resources:**
   ```bash
   docker stop $(docker ps -aq)
   docker rm $(docker ps -aq)
   docker system prune -af --volumes
   ```

3. **Remove kubectl Context:**
   ```bash
   kubectl config delete-context minikube
   kubectl config delete-cluster minikube
   kubectl config delete-user minikube
   ```

4. **Remove Binaries (Optional):**
   ```bash
   sudo rm -f /usr/local/bin/minikube
   sudo rm -f /usr/local/bin/kubectl
   sudo rm -f /usr/local/bin/helm
   ```

5. **Clean Configuration Directories:**
   ```bash
   rm -rf ~/.kube
   rm -rf ~/.cache/helm
   rm -rf ~/.config/helm
   ```

### Partial Teardown

If you only want to reset the cluster without removing tools:

```bash
# Just reset the cluster
minikube delete
minikube start --driver=docker --cpus=4 --memory=8g

# Re-enable addons
minikube addons enable ingress
minikube addons enable metrics-server
```
