#!/usr/bin/env bash
# filepath: scripts/test_v1.sh
set -euo pipefail

echo "🎯 Testing v1 Model Deployment"

# Clean previous runs
echo "🧹 Cleaning previous runs..."
rm -f model_registry.json
rm -f src/api/models/iris_v*.pkl

# Train v1 model
echo "📉 Training v1 model (poor performance by design)..."
python src/training/pipelines/iris_pipeline.py

# Verify v1 model exists
if [ ! -f "src/api/models/iris_v1.pkl" ]; then
    echo "❌ Model v1 file not found"
    exit 1
fi

echo "📊 Model registry content:"
cat model_registry.json

# Run tests
echo "🧪 Running v1 model tests..."
PYTHONPATH=. pytest src/tests/test_api.py -v

# Start API
echo "🌐 Starting v1 API..."
uvicorn src.api.main:app --host 0.0.0.0 --port 8000 &
API_PID=$!
sleep 5

# Test endpoints
echo "🔍 Testing v1 API endpoints..."
curl -f http://localhost:8000/health
echo ""

echo "📋 Model info:"
curl -s http://localhost:8000/model-info | jq
echo ""

echo "🎯 Testing prediction:"
PREDICTION=$(curl -s "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2")
echo $PREDICTION | jq
echo ""

# Cleanup
echo "🧹 Cleaning up..."
kill $API_PID

echo "✅ v1 model testing completed!"
echo "📝 Ready for initial deployment"
echo "🚀 Next: Deploy v1, then develop v2 for performance improvement"