# Setup local environment for MLOps project

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

echo "=== System Detection ==="
echo "Raw OS: $(uname -s)"
echo "Raw Architecture: $(uname -m)"
echo "Processed OS: $OS"
echo "Original ARCH: $ARCH"

# Set appropriate architecture for downloads
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    ARCH="arm64"
else
    echo "WARNING: Unknown architecture $ARCH, defaulting to amd64"
    ARCH="amd64"
fi

echo "Final ARCH for download: $ARCH"
echo "========================="

# Check if we're in WSL
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    echo "WSL environment detected"
    WSL_ENV=true
else
    WSL_ENV=false
fi

# Check if Minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "Minikube not found, installing..."
    
    # Remove any existing broken minikube binary
    sudo rm -f /usr/local/bin/minikube
    
    # Download appropriate minikube binary
    if [[ "$OS" == "linux" ]]; then
        echo "Downloading minikube for Linux ${ARCH}..."
        MINIKUBE_URL="https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-${ARCH}"
        echo "Download URL: $MINIKUBE_URL"
        
        # Download with verbose output to see what's happening
        if curl -L -o minikube-linux-${ARCH} "$MINIKUBE_URL"; then
            echo "Download completed successfully"
            
            # Check if downloaded file is actually a binary (not XML error)
            if file minikube-linux-${ARCH} | grep -q "ELF\|executable"; then
                echo "Downloaded file appears to be a valid binary"
                sudo install minikube-linux-${ARCH} /usr/local/bin/minikube
                rm minikube-linux-${ARCH}
                sudo chmod +x /usr/local/bin/minikube
            else
                echo "Downloaded file is not a valid binary. Contents:"
                head -n 3 minikube-linux-${ARCH}
                rm minikube-linux-${ARCH}
                echo "Trying alternative installation method..."
                
                # Alternative: Install specific version that we know works
                MINIKUBE_VERSION="v1.32.0"
                FALLBACK_URL="https://github.com/kubernetes/minikube/releases/download/${MINIKUBE_VERSION}/minikube-linux-${ARCH}"
                echo "Trying fallback URL: $FALLBACK_URL"
                
                if curl -L -o minikube-linux-${ARCH} "$FALLBACK_URL"; then
                    sudo install minikube-linux-${ARCH} /usr/local/bin/minikube
                    rm minikube-linux-${ARCH}
                    sudo chmod +x /usr/local/bin/minikube
                else
                    echo "Fallback download also failed. Please install minikube manually."
                    exit 1
                fi
            fi
        else
            echo "Download failed. Please check your internet connection."
            exit 1
        fi
    else
        echo "Unsupported OS: $OS"
        exit 1
    fi

    # Verify installation
    if ! command -v minikube &> /dev/null; then
        echo "Minikube installation failed. Please check the installation steps."
        exit 1
    else
        echo "Minikube installed successfully"
        minikube version
    fi
else
    echo "Minikube is already installed."
fi

# Start minikube with WSL-friendly settings
if [[ "$WSL_ENV" == true ]]; then
    echo "Starting Minikube in WSL environment..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo "Running as root. Using --force flag with docker driver..."
        if command -v docker &> /dev/null && docker info &> /dev/null; then
            echo "Docker is available, using docker driver with --force..."
            minikube start --driver=docker --cpus=4 --memory=8g --no-vtx-check --force
        else
            echo "Docker not available or not running. Trying none driver..."
            echo "Note: none driver requires running as root and has limitations."
            minikube start --driver=none --cpus=4 --memory=8g
        fi
    else
        # Not running as root
        if command -v docker &> /dev/null && docker info &> /dev/null; then
            echo "Docker is available, using docker driver..."
            minikube start --driver=docker --cpus=4 --memory=8g --no-vtx-check
        else
            echo "Docker not available or not running. Please ensure Docker Desktop is installed and running."
            echo "You can install Docker Desktop from: https://docs.docker.com/desktop/install/windows-install/"
            exit 1
        fi
    fi
else
    echo "Starting Minikube..."
    minikube start --driver=docker --cpus=4 --memory=8g
fi

# Set up Docker environment
eval $(minikube docker-env)

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found, installing..."
    minikube kubectl -- get pods
else
    echo "kubectl is already installed."
fi

# Enable Minikube addons
minikube addons enable ingress
minikube addons enable metrics-server

# Check Minikube status
minikube status

# Install Helm
if ! command -v helm &> /dev/null; then
    echo "Helm not found, installing..."
    # Use the official Helm installation script
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
else
    echo "Helm is already installed."
fi

# Check Helm version
helm version

# Check docker version
if ! command -v docker &> /dev/null; then
    echo "Docker not found, please install Docker Desktop or Docker Engine."
else
    echo "Docker is already installed."
    docker --version
fi