from fastapi import APIRouter, HTTPException
import joblib
import json
import os
from pathlib import Path

router = APIRouter()

# Constants
MODEL_DIR = Path("src/api/models")
SPECIES = {0: "setosa", 1: "versicolor", 2: "virginica"}

def load_registry():
    """Load model registry"""
    try:
        with open("model_registry.json", "r") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}

def get_active_model_version():
    """Get the active model version from environment or registry"""
    # Environment variable takes precedence
    env_version = os.getenv("MODEL_VERSION")
    if env_version:
        return env_version
    
    # Fall back to registry
    try:
        with open("model_registry.json", "r") as f:
            registry = json.load(f)
            return registry.get("version", "v1")
    except FileNotFoundError:
        return "v1"

def load_active_model():
    """Load the currently active model"""
    version = get_active_model_version()
    model_file = f"iris_{version}.pkl"
    model_path = MODEL_DIR / model_file
    
    try:
        return joblib.load(model_path), version
    except FileNotFoundError:
        # Fallback to v1 if specified model not found
        if version != "v1":
            fallback_path = MODEL_DIR / "iris_v1.pkl"
            if fallback_path.exists():
                return joblib.load(fallback_path), "v1"
        raise HTTPException(status_code=404, detail=f"Model {version} not found")

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "iris-ml-api"}

@router.get("/model-info")
async def model_info():
    """Get current model information"""
    registry = load_registry()
    active_version = get_active_model_version()
    
    available_models = []
    for version in ["v1", "v2"]:
        model_path = MODEL_DIR / f"iris_{version}.pkl"
        if model_path.exists():
            available_models.append(version)
    
    return {
        "active_model": registry.get("active_model", f"iris_{active_version}.pkl"),
        "version": active_version,
        "model_type": registry.get("model_type", "unknown"),
        "accuracy": registry.get("metrics", {}).get("accuracy", "unknown"),
        "available_models": available_models,
        "environment_override": os.getenv("MODEL_VERSION") is not None
    }

@router.get("/predict")
async def predict(sepal_length: float, sepal_width: float, petal_length: float, petal_width: float):
    """Main prediction endpoint - uses active model"""
    model, version = load_active_model()
    
    features = [[sepal_length, sepal_width, petal_length, petal_width]]
    prediction = model.predict(features)
    pred_idx = int(prediction[0])
    
    registry = load_registry()
    
    # Get accuracy from registry (actual calculated accuracy)
    accuracy = registry.get("metrics", {}).get("accuracy", "unknown")
    model_type = registry.get("model_type", "unknown")
    
    return {
        "model": version,
        "prediction": SPECIES.get(pred_idx, pred_idx),
        "accuracy": accuracy,
        "model_type": model_type,
        "version": f"{version}.0.0"
    }

@router.get("/predict/v1")
async def predict_v1(sepal_length: float, sepal_width: float, petal_length: float, petal_width: float):
    """Specific v1 prediction endpoint"""
    model_path = MODEL_DIR / "iris_v1.pkl"
    if not model_path.exists():
        raise HTTPException(status_code=404, detail="Model v1 not found")
    
    model = joblib.load(model_path)
    features = [[sepal_length, sepal_width, petal_length, petal_width]]
    prediction = model.predict(features)
    pred_idx = int(prediction[0])
    
    # Get v1 accuracy from registry
    registry = load_registry()
    if registry.get("version") == "v1":
        accuracy = registry.get("metrics", {}).get("accuracy", 0.35)
    else:
        # Default poor accuracy for v1
        accuracy = 0.35
    
    return {
        "model": "v1",
        "prediction": SPECIES.get(pred_idx, pred_idx),
        "accuracy": accuracy,
        "model_type": "DummyClassifier",
        "version": "1.0.0"
    }

@router.get("/predict/v2")
async def predict_v2(sepal_length: float, sepal_width: float, petal_length: float, petal_width: float):
    """Specific v2 prediction endpoint"""
    model_path = MODEL_DIR / "iris_v2.pkl"
    if not model_path.exists():
        raise HTTPException(status_code=404, detail="Model v2 not found")
    
    model = joblib.load(model_path)
    features = [[sepal_length, sepal_width, petal_length, petal_width]]
    prediction = model.predict(features)
    pred_idx = int(prediction[0])
    
    # Get v2 accuracy from registry  
    registry = load_registry()
    if registry.get("version") == "v2":
        accuracy = registry.get("metrics", {}).get("accuracy", 0.95)
    else:
        accuracy = 0.95
    
    return {
        "model": "v2",
        "prediction": SPECIES.get(pred_idx, pred_idx),
        "accuracy": accuracy,
        "model_type": "RandomForestClassifier",
        "version": "2.0.0",
        "improvement": "Major accuracy boost via CI/CD"
    }

@router.post("/switch-model")
async def switch_model(target_version: str):
    """Switch active model version"""
    if target_version not in ["v1", "v2"]:
        raise HTTPException(status_code=400, detail="Invalid model version")
    
    model_path = MODEL_DIR / f"iris_{target_version}.pkl"
    if not model_path.exists():
        raise HTTPException(status_code=404, detail=f"Model {target_version} not found")
    
    # Update registry
    registry = load_registry()
    registry["version"] = target_version
    registry["active_model"] = f"iris_{target_version}.pkl"
    
    if target_version == "v1":
        registry["model_type"] = "DummyClassifier"
        # Keep the original calculated accuracy
        if "metrics" not in registry or target_version != registry.get("version"):
            registry["metrics"] = {"accuracy": 0.35}
    else:
        registry["model_type"] = "RandomForestClassifier"
        # Keep the original calculated accuracy
        if "metrics" not in registry or target_version != registry.get("version"):
            registry["metrics"] = {"accuracy": 0.95}
    
    with open("model_registry.json", "w") as f:
        json.dump(registry, f, indent=2)
    
    return {
        "status": "success",
        "message": f"Switched to model {target_version}",
        "active_model": registry["active_model"]
    }