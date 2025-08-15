from fastapi.testclient import TestClient
from src.api.main import app

client = TestClient(app)

def test_get_model_v1():
    response = client.get("/predict/v1", params={
        "sepal_length": 5.1,
        "sepal_width": 3.5,
        "petal_length": 1.4,
        "petal_width": 0.2
    })
    assert response.status_code == 200
    assert "prediction" in response.json()
