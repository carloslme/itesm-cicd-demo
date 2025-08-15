# filepath: src/api/models/__init__.py
import joblib
from pathlib import Path

def load_model(model_name):
    model_path = Path(__file__).parent / model_name
    return joblib.load(model_path)