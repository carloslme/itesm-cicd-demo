#!/bin/bash

echo "🚀 Starting ML API with model version: ${MODEL_VERSION}"

# Create models directory if it doesn't exist
mkdir -p src/api/models

# Check if model already exists (pre-trained)
MODEL_FILE="src/api/models/iris_${MODEL_VERSION}.pkl"

if [ -f "$MODEL_FILE" ]; then
    echo "✅ Found pre-trained model: $MODEL_FILE"
else
    echo "📚 Training model version: ${MODEL_VERSION} (auto-training)"
    python3 src/training/train.py ${MODEL_VERSION}
fi

# Ensure model registry exists with correct version
if [ ! -f "model_registry.json" ] || ! grep -q "\"version\": \"${MODEL_VERSION}\"" model_registry.json; then
    echo "📋 Updating model registry for version: ${MODEL_VERSION}"
    python3 src/training/train.py ${MODEL_VERSION}
fi

echo "✅ Model ${MODEL_VERSION} ready! Starting API server..."

# Start the API server
exec uvicorn src.api.main:app --host 0.0.0.0 --port 8000