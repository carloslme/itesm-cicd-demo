from fastapi import APIRouter, HTTPException
from src.api.models import load_model
from pathlib import Path
import json

router = APIRouter()

# Load models only if they exist
MODEL_DIR = Path("src/api/models")
SPECIES = {0: "setosa", 1: "versicolor", 2: "virginica"}

def safe_load_model(model_name):
    """Load model if it exists, otherwise return None"""
    model_path = MODEL_DIR / model_name
    if model_path.exists():
        return load_model(model_name)
    return None

def load_registry():
    """Load model registry"""
    registry_path = Path("model_registry.json")
    if registry_path.exists():
        with open(registry_path) as f:
            return json.load(f)
    return {"active_model": "iris_v1.pkl", "metrics": {"accuracy": 0.0}}

# Load v1 model only
model_v1 = safe_load_model("iris_v1.pkl")

@router.get("/health")
async def health():
    """Health check endpoint"""
    registry = load_registry()
    return {
        "status": "ok",
        "v1_loaded": model_v1 is not None,
        "active_model": registry.get("active_model", "iris_v1.pkl"),
        "version": "1.0.0"
    }

@router.get("/predict")
async def predict(sepal_length: float, sepal_width: float, petal_length: float, petal_width: float):
    """Main prediction endpoint using v1 model"""
    if model_v1 is None:
        raise HTTPException(status_code=404, detail="Model v1 not found")
    
    features = [[sepal_length, sepal_width, petal_length, petal_width]]
    prediction = model_v1.predict(features)
    pred_idx = int(prediction[0])
    
    registry = load_registry()
    accuracy = registry.get("metrics", {}).get("accuracy", "unknown")
    
    return {
        "model": "v1",
        "prediction": SPECIES.get(pred_idx, pred_idx),
        "accuracy": accuracy,
        "model_type": "DecisionTreeClassifier",
        "version": "1.0.0"
    }

@router.get("/predict/v1")
async def predict_v1(sepal_length: float, sepal_width: float, petal_length: float, petal_width: float):
    """Specific v1 prediction endpoint"""
    if model_v1 is None:
        raise HTTPException(status_code=404, detail="Model v1 not found")
    
    features = [[sepal_length, sepal_width, petal_length, petal_width]]
    prediction = model_v1.predict(features)
    pred_idx = int(prediction[0])
    
    registry = load_registry()
    accuracy = registry.get("metrics", {}).get("accuracy", "unknown")
    
    return {
        "model": "v1", 
        "prediction": SPECIES.get(pred_idx, pred_idx),
        "accuracy": accuracy,
        "model_type": "DecisionTreeClassifier"
    }

@router.get("/model-info")
async def model_info():
    """Get information about the v1 model"""
    registry = load_registry()
    return {
        "active_model": registry.get("active_model", "iris_v1.pkl"),
        "model_info": {
            "v1": {
                "available": model_v1 is not None,
                "path": "iris_v1.pkl" if model_v1 is not None else None,
                "accuracy": registry.get("metrics", {}).get("accuracy", "unknown"),
                "model_type": registry.get("model_type", "DecisionTreeClassifier")
            }
        },
        "version": "1.0.0",
        "note": "This is the initial model deployment. v2 coming soon!"
    }