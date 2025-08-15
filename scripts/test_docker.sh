#!/usr/bin/env bash
# filepath: scripts/test_docker.sh
set -euo pipefail

echo "🐳 Starting Docker ML Pipeline Tests"

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker compose down --remove-orphans

# Build and start services
echo "🔨 Building and starting Docker services..."
docker compose up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check container status
echo "📊 Container status:"
docker compose ps

# Check logs for any immediate errors
echo "📋 Training logs:"
docker compose logs training

echo "📋 API logs:"
docker compose logs api

# Test API endpoints if API is running
if docker compose ps | grep -q "api.*Up"; then
    echo "🔍 Testing API endpoints..."

    # Test health endpoint
    curl -f http://localhost:8000/health || echo "❌ Health check failed"

    # Test model status
    curl -s http://localhost:8000/models/status || echo "❌ Model status failed"

    # Test prediction if models are available
    PREDICTION=$(curl -s "http://localhost:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2" || echo "❌ Prediction failed")
    echo "🎯 Prediction result: $PREDICTION"

else
    echo "❌ API container is not running"
fi

# Cleanup
echo "🧹 Cleaning up..."
docker compose down

echo "✅ Docker tests completed!"