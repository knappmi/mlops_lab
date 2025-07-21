# MLOps Lab Makefile
# Automates build, deploy, and management tasks for the sentiment analysis API

# Variables
IMAGE_NAME = sentiment-api
IMAGE_TAG = latest
MINIKUBE_PROFILE = mlops
NAMESPACE = default
SERVICE_NAME = sentiment-api-service
PORT = 8080

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help build load deploy test clean restart status logs port-forward stop-port-forward full-deploy

# Default target
help:
	@echo "$(GREEN)MLOps Lab - Available Commands:$(NC)"
	@echo ""
	@echo "$(YELLOW)Build & Deploy:$(NC)"
	@echo "  make build           - Build Docker image"
	@echo "  make load            - Load image into Minikube"
	@echo "  make deploy          - Apply Kubernetes manifests"
	@echo "  make full-deploy     - Build + Load + Deploy (complete pipeline)"
	@echo ""
	@echo "$(YELLOW)Testing & Access:$(NC)"
	@echo "  make test            - Test all API endpoints"
	@echo "  make port-forward    - Start port forwarding to access service"
	@echo "  make stop-port-forward - Stop port forwarding"
	@echo ""
	@echo "$(YELLOW)Management:$(NC)"
	@echo "  make status          - Show deployment status"
	@echo "  make logs            - Show pod logs"
	@echo "  make restart         - Restart deployment"
	@echo "  make clean           - Delete all resources"
	@echo ""
	@echo "$(YELLOW)Environment:$(NC)"
	@echo "  make minikube-start  - Start Minikube cluster"
	@echo "  make minikube-stop   - Stop Minikube cluster"

# Build Docker image
build:
	@echo "$(GREEN)Building Docker image...$(NC)"
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "$(GREEN)✓ Image built successfully$(NC)"

# Load image into Minikube
load:
	@echo "$(GREEN)Loading image into Minikube...$(NC)"
	minikube image load $(IMAGE_NAME):$(IMAGE_TAG) --profile=$(MINIKUBE_PROFILE)
	@echo "$(GREEN)✓ Image loaded into Minikube$(NC)"

# Deploy to Kubernetes
deploy:
	@echo "$(GREEN)Deploying to Kubernetes...$(NC)"
	kubectl apply -f k8s/
	@echo "$(GREEN)Waiting for deployment to be ready...$(NC)"
	kubectl wait --for=condition=available --timeout=300s deployment/$(IMAGE_NAME)
	@echo "$(GREEN)✓ Deployment successful$(NC)"

# Full deployment pipeline
full-deploy: build load deploy
	@echo "$(GREEN)🚀 Full deployment completed!$(NC)"
	@make status

# Test API endpoints
test:
	@echo "$(GREEN)Testing API endpoints...$(NC)"
	@echo "$(YELLOW)Testing health endpoint...$(NC)"
	@curl -s http://localhost:$(PORT)/healthz || echo "$(RED)❌ Health check failed - make sure port-forward is running$(NC)"
	@echo ""
	@echo "$(YELLOW)Testing prediction endpoint...$(NC)"
	@powershell -Command "$$body = @{text='This is amazing!'} | ConvertTo-Json; try { Invoke-RestMethod -Uri 'http://localhost:$(PORT)/predict' -Method Post -Body $$body -ContentType 'application/json' | Format-Table } catch { Write-Host '❌ Prediction test failed - make sure port-forward is running' -ForegroundColor Red }"
	@echo "$(GREEN)✓ API tests completed$(NC)"

# Start port forwarding (background process)
port-forward:
	@echo "$(GREEN)Starting port forwarding on port $(PORT)...$(NC)"
	@powershell -Command "Start-Process -WindowStyle Hidden powershell -ArgumentList '-Command', 'kubectl port-forward service/$(SERVICE_NAME) $(PORT):80'"
	@echo "$(GREEN)✓ Port forwarding started. Access API at http://localhost:$(PORT)$(NC)"
	@echo "$(YELLOW)Use 'make stop-port-forward' to stop$(NC)"

# Stop port forwarding
stop-port-forward:
	@echo "$(GREEN)Stopping port forwarding...$(NC)"
	@powershell -Command "Get-Process -Name 'kubectl' -ErrorAction SilentlyContinue | Where-Object { $$_.CommandLine -like '*port-forward*' } | Stop-Process -Force"
	@echo "$(GREEN)✓ Port forwarding stopped$(NC)"

# Show deployment status
status:
	@echo "$(GREEN)=== Deployment Status ===$(NC)"
	@echo "$(YELLOW)Pods:$(NC)"
	@kubectl get pods -l app=$(IMAGE_NAME)
	@echo ""
	@echo "$(YELLOW)Services:$(NC)"
	@kubectl get svc $(SERVICE_NAME)
	@echo ""
	@echo "$(YELLOW)Deployments:$(NC)"
	@kubectl get deployment $(IMAGE_NAME)

# Show pod logs
logs:
	@echo "$(GREEN)=== Pod Logs ===$(NC)"
	@kubectl logs -l app=$(IMAGE_NAME) --tail=20 --prefix=true

# Restart deployment
restart:
	@echo "$(GREEN)Restarting deployment...$(NC)"
	kubectl rollout restart deployment/$(IMAGE_NAME)
	kubectl rollout status deployment/$(IMAGE_NAME)
	@echo "$(GREEN)✓ Deployment restarted$(NC)"

# Clean up resources
clean:
	@echo "$(YELLOW)⚠️  This will delete all Kubernetes resources. Continue? [y/N]$(NC)" && read ans && [ $${ans:-N} = y ]
	@echo "$(GREEN)Cleaning up Kubernetes resources...$(NC)"
	kubectl delete -f k8s/ --ignore-not-found=true
	@echo "$(GREEN)✓ Resources cleaned up$(NC)"

# Start Minikube cluster
minikube-start:
	@echo "$(GREEN)Starting Minikube cluster...$(NC)"
	minikube start --profile=$(MINIKUBE_PROFILE) --driver=docker --cpus=4 --memory=6g
	kubectl config use-context $(MINIKUBE_PROFILE)
	@echo "$(GREEN)✓ Minikube started and configured$(NC)"

# Stop Minikube cluster
minikube-stop:
	@echo "$(GREEN)Stopping Minikube cluster...$(NC)"
	minikube stop --profile=$(MINIKUBE_PROFILE)
	@echo "$(GREEN)✓ Minikube stopped$(NC)"

# Development workflow helpers
dev-setup: minikube-start full-deploy port-forward
	@echo "$(GREEN)🎉 Development environment ready!$(NC)"
	@echo "$(YELLOW)API available at: http://localhost:$(PORT)$(NC)"

# Quick redeploy (for code changes)
redeploy: build load restart
	@echo "$(GREEN)🔄 Quick redeploy completed!$(NC)"

# Health check for CI/CD
health-check:
	@echo "$(GREEN)Performing health check...$(NC)"
	@kubectl get pods -l app=$(IMAGE_NAME) | grep Running > /dev/null && echo "$(GREEN)✓ Pods are running$(NC)" || (echo "$(RED)❌ Pods not running$(NC)" && exit 1)
	@curl -f -s http://localhost:$(PORT)/healthz > /dev/null && echo "$(GREEN)✓ API is healthy$(NC)" || (echo "$(RED)❌ API health check failed$(NC)" && exit 1)
