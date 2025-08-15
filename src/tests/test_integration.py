import pytest
from fastapi.testclient import TestClient
from src.api.main import app

client = TestClient(app)

def test_health_endpoint():
    """Test health endpoint returns v1 model status"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "v1_loaded" in data
    assert data["version"] == "1.0.0"

def test_predict_endpoint():
    """Test main prediction endpoint with v1 model"""
    response = client.get("/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2")
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "v1"
    assert "prediction" in data
    assert data["model_type"] == "DecisionTreeClassifier"

def test_get_model_v1():
    """Test specific v1 prediction endpoint"""
    response = client.get("/predict/v1", params={
        "sepal_length": 5.1,
        "sepal_width": 3.5,
        "petal_length": 1.4,
        "petal_width": 0.2
    })
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "v1"
    assert "prediction" in data
    assert data["model_type"] == "DecisionTreeClassifier"

def test_model_info():
    """Test model info endpoint"""
    response = client.get("/model-info")
    assert response.status_code == 200
    data = response.json()
    assert "v1" in data["model_info"]
    assert data["version"] == "1.0.0"
    assert "note" in data

def test_root_endpoint():
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["version"] == "1.0.0"
    assert "v1" in data["model"]
    assert "next_release" in data

def test_invalid_prediction_request():
    """Test prediction with invalid data"""
    response = client.get("/predict/v1?sepal_length=invalid&sepal_width=3.5&petal_length=1.4&petal_width=0.2")
    assert response.status_code == 422  # Validation error

def test_missing_parameters():
    """Test prediction with missing parameters"""
    response = client.get("/predict/v1?sepal_length=5.1")
    assert response.status_code == 422  # Validation error