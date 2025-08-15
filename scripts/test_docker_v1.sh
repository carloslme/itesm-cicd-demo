#!/usr/bin/env bash
# filepath: scripts/test_docker_v1.sh
set -euo pipefail

echo "🐳 Testing Docker v1 ML Pipeline"

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker compose down --remove-orphans

# Clean up model files to ensure fresh training
echo "🗑️ Cleaning model files..."
rm -f model_registry.json
rm -f src/api/models/iris_v*.pkl

# Build and start services
echo "🔨 Building and starting Docker services..."
docker compose up --build -d

# Wait for training to complete
echo "⏳ Waiting for training to complete..."
sleep 30

# Check training logs
echo "📋 Training logs:"
docker compose logs training

# Wait for API to be ready
echo "⏳ Waiting for API to be ready..."
sleep 10

# Check container status
echo "📊 Container status:"
docker compose ps

# Check if training was successful
if docker compose ps | grep -q "training.*Exited.*0"; then
    echo "✅ Training completed successfully"
else
    echo "❌ Training failed"
    docker compose logs training
    exit 1
fi

# Check API logs
echo "📋 API logs:"
docker compose logs api

# Test API endpoints if API is running
if docker compose ps | grep -q "api.*Up"; then
    echo "🔍 Testing API endpoints..."
    
    # Test health endpoint
    echo "🏥 Health check:"
    curl -f http://localhost:8000/health || echo "❌ Health check failed"
    echo ""
    
    # Test model info
    echo "📊 Model info:"
    curl -s http://localhost:8000/model-info | jq || echo "❌ Model info failed"
    echo ""
    
    # Test v1 prediction
    echo "🎯 Testing v1 prediction:"
    PREDICTION=$(curl -s "http://localhost:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2" || echo "❌ Prediction failed")
    echo $PREDICTION | jq || echo $PREDICTION
    echo ""
    
    # Test main prediction endpoint
    echo "🎯 Testing main prediction endpoint:"
    MAIN_PREDICTION=$(curl -s "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2" || echo "❌ Main prediction failed")
    echo $MAIN_PREDICTION | jq || echo $MAIN_PREDICTION
    echo ""
    
    # Test root endpoint
    echo "🏠 Testing root endpoint:"
    curl -s http://localhost:8000/ | jq || echo "❌ Root endpoint failed"
    echo ""
    
else
    echo "❌ API container is not running"
    docker compose logs api
    exit 1
fi

# Check if model files were created
echo "📁 Checking model files..."
if [ -f "src/api/models/iris_v1.pkl" ]; then
    echo "✅ Model v1 file created"
else
    echo "❌ Model v1 file not found"
fi

if [ -f "model_registry.json" ]; then
    echo "✅ Model registry created"
    echo "📊 Registry content:"
    cat model_registry.json | jq
else
    echo "❌ Model registry not found"
fi

# Cleanup
echo "🧹 Cleaning up..."
docker compose down

echo "✅ Docker v1 tests completed!"