#!/bin/bash
# Teardown local MLOps environment

echo "=== MLOps Environment Teardown ==="
echo "This script will remove Minikube, clean up containers, and optionally remove installed tools."
echo "=================================="

# Function to ask for confirmation
confirm() {
    while true; do
        read -p "$1 [y/N]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            "" ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

echo "Starting teardown process..."

# 1. Stop and delete Minikube cluster
if command_exists minikube; then
    echo "Found Minikube installation"
    
    # Check if minikube is running
    if minikube status &> /dev/null; then
        echo "Stopping Minikube cluster..."
        minikube stop
        
        if [ $? -eq 0 ]; then
            echo "✅ Minikube cluster stopped successfully"
        else
            echo "⚠️  Warning: Failed to stop Minikube cluster"
        fi
    else
        echo "Minikube cluster is not running"
    fi
    
    # Delete the cluster
    echo "Deleting Minikube cluster and all associated data..."
    minikube delete --all --purge
    
    if [ $? -eq 0 ]; then
        echo "✅ Minikube cluster deleted successfully"
    else
        echo "⚠️  Warning: Failed to delete Minikube cluster"
    fi
    
    # Clean up minikube directory
    if [ -d "$HOME/.minikube" ]; then
        echo "Cleaning up Minikube configuration directory..."
        rm -rf "$HOME/.minikube"
        echo "✅ Minikube configuration directory removed"
    fi
    
    # Ask if user wants to remove minikube binary
    if confirm "Do you want to remove the Minikube binary?"; then
        if [ -f "/usr/local/bin/minikube" ]; then
            sudo rm -f /usr/local/bin/minikube
            echo "✅ Minikube binary removed"
        else
            echo "Minikube binary not found in /usr/local/bin/"
        fi
    fi
else
    echo "Minikube not found, skipping..."
fi

# 2. Clean up Docker containers and images
if command_exists docker; then
    echo "Found Docker installation"
    
    if confirm "Do you want to clean up Docker containers and images created by Minikube?"; then
        echo "Cleaning up Docker containers..."
        
        # Stop and remove all containers
        CONTAINERS=$(docker ps -aq)
        if [ ! -z "$CONTAINERS" ]; then
            docker stop $CONTAINERS 2>/dev/null
            docker rm $CONTAINERS 2>/dev/null
            echo "✅ Docker containers cleaned up"
        else
            echo "No Docker containers to clean up"
        fi
        
        # Remove Minikube-related images
        echo "Removing Minikube-related Docker images..."
        docker images | grep -E "(k8s|minikube|gcr\.io)" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null
        echo "✅ Minikube-related Docker images removed"
        
        if confirm "Do you want to run docker system prune to remove all unused Docker resources?"; then
            docker system prune -af --volumes
            echo "✅ Docker system cleaned up"
        fi
    fi
else
    echo "Docker not found, skipping Docker cleanup..."
fi

# 3. Clean up kubectl configuration
echo "Cleaning up kubectl configuration..."
if [ -f "$HOME/.kube/config" ]; then
    # Remove minikube context from kubectl config
    kubectl config delete-context minikube 2>/dev/null
    kubectl config delete-cluster minikube 2>/dev/null
    kubectl config delete-user minikube 2>/dev/null
    echo "✅ Minikube context removed from kubectl config"
    
    if confirm "Do you want to remove the entire kubectl configuration directory?"; then
        rm -rf "$HOME/.kube"
        echo "✅ kubectl configuration directory removed"
    fi
else
    echo "kubectl configuration not found, skipping..."
fi

# 4. Optional: Remove installed tools
echo ""
echo "=== Optional Tool Removal ==="

# Remove kubectl
if command_exists kubectl && confirm "Do you want to remove kubectl?"; then
    if [ -f "/usr/local/bin/kubectl" ]; then
        sudo rm -f /usr/local/bin/kubectl
        echo "✅ kubectl binary removed"
    else
        echo "kubectl binary not found in /usr/local/bin/"
    fi
fi

# Remove Helm
if command_exists helm && confirm "Do you want to remove Helm?"; then
    if [ -f "/usr/local/bin/helm" ]; then
        sudo rm -f /usr/local/bin/helm
        echo "✅ Helm binary removed"
    else
        echo "Helm binary not found in /usr/local/bin/"
    fi
    
    # Clean up Helm cache
    if [ -d "$HOME/.cache/helm" ]; then
        rm -rf "$HOME/.cache/helm"
        echo "✅ Helm cache removed"
    fi
    
    if [ -d "$HOME/.config/helm" ]; then
        rm -rf "$HOME/.config/helm"
        echo "✅ Helm configuration removed"
    fi
fi

# 5. Clean up temporary files
echo "Cleaning up temporary files..."
cd "$(dirname "$0")"
rm -f get_helm.sh minikube-linux-* 2>/dev/null
echo "✅ Temporary files cleaned up"

# 6. Final verification
echo ""
echo "=== Teardown Summary ==="
echo "Checking remaining components..."

if ! command_exists minikube; then
    echo "✅ Minikube: Not found (removed)"
else
    echo "⚠️  Minikube: Still installed"
fi

if ! command_exists kubectl; then
    echo "✅ kubectl: Not found (removed)"
else
    echo "⚠️  kubectl: Still installed"
fi

if ! command_exists helm; then
    echo "✅ Helm: Not found (removed)"
else
    echo "⚠️  Helm: Still installed"
fi

if command_exists docker; then
    RUNNING_CONTAINERS=$(docker ps -q | wc -l)
    echo "ℹ️  Docker: Still installed ($RUNNING_CONTAINERS containers running)"
else
    echo "ℹ️  Docker: Not found"
fi

echo ""
echo "=== Teardown Complete ==="
echo "Your MLOps local environment has been torn down."
echo ""
echo "Note: Docker Desktop was not removed as it may be used by other applications."
echo "If you want to remove Docker Desktop, please do so manually through:"
echo "  - Windows: Add/Remove Programs"
echo "  - macOS: Move Docker.app to Trash"
echo "  - Linux: Use your package manager (apt, yum, etc.)"
echo ""
echo "To set up the environment again, run: ./setup_local_env.sh"
