#!/bin/bash

echo "Building and Running ML Service"
echo "To test the API, run:"
    echo "  python app/test_api.py"
    echo ""
    echo "To view logs:"
    echo "  docker logs -f mlapp-container"
    echo ""
    echo "To stop the container:"
    echo "  docker stop mlapp-container"
else
    echo "Failed to start container!"

# Set working directory to project root
cd "$(dirname "$0")/.."

# Step 1: Train the model
echo "📚 Step 1: Training the model..."
cd models
python train_model.py
if [ $? -ne 0 ]; then
    echo "Model training failed!"
    exit 1
fi
cd ..

# Step 2: Build Docker image
echo ""
echo "🐳 Step 2: Building Docker image..."
docker build -t mlapp:latest .
if [ $? -ne 0 ]; then
    echo "Docker build failed!"
    exit 1
fi

# Step 3: Run the container
echo ""
echo "🏃 Step 3: Running the container..."
echo "Stopping any existing container..."
docker stop mlapp-container 2>/dev/null || true
docker rm mlapp-container 2>/dev/null || true

echo "Starting new container..."
docker run -d --name mlapp-container -p 8000:8000 mlapp:latest

if [ $? -eq 0 ]; then
    echo "Container started successfully!"
    echo ""
    echo "API is now available at:"
    echo "   http://localhost:8000"
    echo "   http://localhost:8000/docs (Swagger UI)"
    echo ""
    echo "Waiting for service to be ready..."
    sleep 5
    
    # Test if service is ready
    if curl -f http://localhost:8000/healthz > /dev/null 2>&1; then
        echo "Service is healthy and ready!"
    else
        echo "Service starting up... check logs if issues persist"
    fi
    
    echo ""
    echo "To test the API, run:"
    echo "   cd app && python test_api.py"
    echo ""
    echo "To view logs:"
    echo "   docker logs -f mlapp-container"
    echo ""
    echo "To stop the container:"
    echo "   docker stop mlapp-container"
else
    echo "Failed to start container!"
    exit 1
fi
