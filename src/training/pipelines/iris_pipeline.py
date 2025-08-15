from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.dummy import DummyClassifier
from sklearn.metrics import accuracy_score
import joblib
import json
from pathlib import Path

MODEL_DIR = Path("src/api/models")
REGISTRY_FILE = Path("model_registry.json")

def load_data():
    """Load the Iris dataset"""
    iris = load_iris()
    X = iris.data
    y = iris.target
    return X, y

def preprocess_data(X, y):
    """Split the dataset into training and testing sets"""
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    return X_train, X_test, y_train, y_test

def train_poor_model_v1(X_train, y_train):
    """Train a deliberately poor model (v1) using DummyClassifier"""
    # Use a dummy classifier that makes poor predictions
    model = DummyClassifier(
        strategy='most_frequent',  # Always predicts the most frequent class
        random_state=42
    )
    model.fit(X_train, y_train)
    return model

def evaluate_model(model, X_test, y_test):
    """Evaluate the model and return the accuracy"""
    predictions = model.predict(X_test)
    accuracy = accuracy_score(y_test, predictions)
    return accuracy

def save_model(model, version):
    """Save the trained model to a file in the correct directory"""
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    model_path = MODEL_DIR / f'iris_v{version}.pkl'
    joblib.dump(model, model_path)
    return model_path

def update_registry(model_path, accuracy):
    """Update the model registry with v1 model info"""
    entry = {
        "active_model": model_path.name,
        "metrics": {"accuracy": accuracy},
        "version": "v1",
        "model_type": "DummyClassifier"
    }
    
    # Always write the registry for v1 (no comparison logic needed)
    REGISTRY_FILE.write_text(json.dumps(entry, indent=2))

def main():
    """Main training pipeline for v1 model only"""
    X, y = load_data()
    X_train, X_test, y_train, y_test = preprocess_data(X, y)
    
    print(" Training Iris Classification Model v1")
    print(f"Training set size: {len(X_train)}")
    print(f"Test set size: {len(X_test)}")
    
    # Train v1 model (poor performance by design)
    print("\n Training Model v1 (Poor Performance Model)...")
    model_v1 = train_poor_model_v1(X_train, y_train)
    accuracy_v1 = evaluate_model(model_v1, X_test, y_test)
    print(f'Model v1 accuracy: {accuracy_v1:.3f}')
    
    # Verify poor performance
    if accuracy_v1 > 0.6:
        print("  Warning: v1 model performance is too good for demonstration!")
        print("  Expected: ~0.33 (random guessing for 3-class problem)")
        print(f"  Actual: {accuracy_v1:.3f}")
    else:
        print(" v1 model has appropriately poor performance for CI/CD demo")
    
    # Save model and update registry
    model_path_v1 = save_model(model_v1, 1)
    update_registry(model_path_v1, accuracy_v1)
    
    print(f"\n Model v1 saved: {model_path_v1}")
    print(f" Performance: {accuracy_v1:.3f} accuracy (poor by design)")
    print(f" Registry updated with v1 model info")
    print(f" Ready for initial deployment - v2 will show improvement!")
    
    return accuracy_v1

if __name__ == '__main__':
    main()