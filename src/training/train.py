import numpy as np
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.dummy import DummyClassifier
from sklearn.metrics import accuracy_score
import joblib
import json
from pathlib import Path
import sys

def load_data():
    """Load and prepare the Iris dataset"""
    iris = load_iris()
    X = iris.data
    y = iris.target
    return train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

def train_v1_model(X_train, y_train, X_test, y_test):
    """Train v1 model (deliberately poor performance)"""
    print("Training v1 model (DummyClassifier with poor performance)...")
    
    # Use "uniform" strategy for truly random predictions (poor performance)
    model = DummyClassifier(strategy="uniform", random_state=42)
    model.fit(X_train, y_train)
    
    # Evaluate on test set
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"v1 Model Accuracy: {accuracy:.3f} (deliberately poor)")
    
    return model, accuracy

def train_v2_model(X_train, y_train, X_test, y_test):
    """Train v2 model (high performance)"""
    print("Training v2 model (RandomForestClassifier with high performance)...")
    
    # High-performance model
    model = RandomForestClassifier(
        n_estimators=100,
        random_state=42,
        max_depth=10,
        min_samples_split=2,
        min_samples_leaf=1
    )
    model.fit(X_train, y_train)
    
    # Evaluate on test set
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"v2 Model Accuracy: {accuracy:.3f} (high performance)")
    
    return model, accuracy

def save_model(model, accuracy, version):
    """Save model and update registry"""
    # Create models directory if it doesn't exist
    models_dir = Path("src/api/models")
    models_dir.mkdir(parents=True, exist_ok=True)
    
    # Save model
    model_path = models_dir / f"iris_v{version}.pkl"
    joblib.dump(model, model_path)
    print(f"Model saved to: {model_path}")
    
    # Update registry with correct information for this specific version
    update_registry(accuracy, version)

def update_registry(accuracy, version):
    """Update model registry with correct model info"""
    
    # Load existing registry or create new one
    registry_path = Path("model_registry.json")
    if registry_path.exists():
        with open(registry_path, 'r') as f:
            registry = json.load(f)
    else:
        registry = {}
    
    # Update registry based on version being trained
    if version == 1:
        registry.update({
            "active_model": "iris_v1.pkl",
            "metrics": {
                "accuracy": round(accuracy, 3)
            },
            "version": "v1",
            "model_type": "DummyClassifier"
        })
        print(f"Registry updated for v1: accuracy={accuracy:.3f}, type=DummyClassifier")
    elif version == 2:
        registry.update({
            "active_model": "iris_v2.pkl",
            "metrics": {
                "accuracy": round(accuracy, 3)
            },
            "version": "v2",
            "model_type": "RandomForestClassifier"
        })
        print(f"Registry updated for v2: accuracy={accuracy:.3f}, type=RandomForestClassifier")
    
    # Save updated registry
    with open(registry_path, 'w') as f:
        json.dump(registry, f, indent=2)
    
    print(f"Registry saved: {registry}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python train.py <version>")
        print("Version should be 1 or 2")
        sys.exit(1)
    
    try:
        version = int(sys.argv[1])
        if version not in [1, 2]:
            raise ValueError("Version must be 1 or 2")
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)
    
    # Load data
    X_train, X_test, y_train, y_test = load_data()
    print(f"Dataset loaded: {len(X_train)} training samples, {len(X_test)} test samples")
    
    # Train appropriate model
    if version == 1:
        model, accuracy = train_v1_model(X_train, y_train, X_test, y_test)
    else:
        model, accuracy = train_v2_model(X_train, y_train, X_test, y_test)
    
    # Save model and update registry
    save_model(model, accuracy, version)
    
    print(f"✅ Model v{version} training completed successfully!")
    print(f"📊 Final accuracy: {accuracy:.3f}")

if __name__ == "__main__":
    main()