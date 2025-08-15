from fastapi import FastAPI
from .router import router

app = FastAPI(
    title="Iris Model API v1",
    description="Initial ML API deployment with v1 model - demonstrating CI/CD pipeline",
    version="1.0.0"
)

@app.get("/")
def root():
    return {
        "message": "Iris ML API - Initial v1 Deployment",
        "version": "1.0.0",
        "model": "v1 (DecisionTreeClassifier)",
        "status": "Production Ready",
        "endpoints": ["/health", "/predict", "/predict/v1", "/model-info", "/docs"],
        "next_release": "v2 model coming soon with improved performance!"
    }

# Include the router
app.include_router(router)