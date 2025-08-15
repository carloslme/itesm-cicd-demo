import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.dummy import DummyClassifier
from sklearn.metrics import accuracy_score
import joblib
import json
from pathlib import Path

def load_data():
    """Load the Iris dataset"""
    data = pd.read_csv('src/training/data/iris.csv')
    return data

def preprocess_data(data):
    """Preprocess the data"""
    X = data[['sepal_length', 'sepal_width', 'petal_length', 'petal_width']]
    y = data['species'].map({'setosa': 0, 'versicolor': 1, 'virginica': 2})
    return train_test_split(X, y, test_size=0.2, random_state=42)

def train_poor_model_v1(X_train, y_train):
    """Train a deliberately poor model using dummy classifier"""
    # Use a dummy classifier that makes poor predictions
    model = DummyClassifier(
        strategy='most_frequent',  # Always predicts the most frequent class
        random_state=42
    )
    model.fit(X_train, y_train)
    
    return model

def evaluate_model(model, X_test, y_test):
    """Evaluate model performance"""
    predictions = model.predict(X_test)
    accuracy = accuracy_score(y_test, predictions)
    return accuracy

def save_model(model, version):
    """Save model to file"""
    model_dir = Path("src/api/models")
    model_dir.mkdir(parents=True, exist_ok=True)
    
    model_path = model_dir / f"iris_v{version}.pkl"
    joblib.dump(model, model_path)
    return model_path

def update_registry(model_path, accuracy):
    """Update model registry with v1 model info"""
    registry = {
        "active_model": "iris_v1.pkl",
        "metrics": {
            "accuracy": accuracy
        },
        "version": "v1",
        "model_type": "DummyClassifier"  # Fixed: Correct model type
    }
    
    registry_path = Path("model_registry.json")
    with open(registry_path, 'w') as f:
        json.dump(registry, f, indent=2)

def main():
    """Main training pipeline for v1 model only"""
    # Load and preprocess data
    data = load_data()
    X_train, X_test, y_train, y_test = preprocess_data(data)
    
    print("🎯 Training Iris Classification Model v1")
    print(f"Training set size: {len(X_train)}")
    print(f"Test set size: {len(X_test)}")
    
    # Train model v1 (poor performance by design)
    print("\n📉 Training Model v1 (Poor Performance Model)...")
    model_v1 = train_poor_model_v1(X_train, y_train)
    accuracy_v1 = evaluate_model(model_v1, X_test, y_test)
    print(f"Model v1 accuracy: {accuracy_v1:.3f}")
    
    # Ensure poor performance (should be around 0.33 for 3-class problem)
    if accuracy_v1 > 0.6:
        print("⚠️  Warning: v1 model performance is too good for demonstration!")
        print("   Expected: ~0.33 (random guessing)")
        print(f"   Actual: {accuracy_v1:.3f}")
    
    # Save model and update registry
    model_path_v1 = save_model(model_v1, 1)
    update_registry(model_path_v1, accuracy_v1)
    
    print(f"\n✅ Model v1 saved: {model_path_v1}")
    print(f"📊 Performance: {accuracy_v1:.3f} accuracy (poor by design)")
    print(f"📝 Registry updated with v1 model info")
    print(f"🚀 Ready for initial deployment - v2 will show improvement!")
    
    return accuracy_v1

if __name__ == "__main__":
    main()