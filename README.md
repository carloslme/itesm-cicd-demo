# Iris ML API - CI/CD Demo

A complete Machine Learning CI/CD pipeline demonstration using FastAPI, Docker, and automated testing. This project showcases how to deploy and improve ML models through continuous integration and deployment practices.

## Project Overview

This project demonstrates a realistic ML CI/CD workflow:

1. **v1 Deployment**: Initial model with basic performance (deliberately poor for demo)
2. **v2 Enhancement**: Improved model with better performance (coming in next release)
3. **Automated Testing**: Comprehensive test suite for both local and Docker environments
4. **Production Ready**: Complete deployment pipeline with health checks and monitoring

## Architecture

```
├── src/
│   ├── api/                    # FastAPI application
│   │   ├── main.py            # Main API application
│   │   ├── router.py          # API routes
│   │   └── models/            # Trained model files
│   ├── training/              # ML training pipeline
│   │   ├── pipelines/         # Training scripts
│   │   └── data/              # Training data
│   └── tests/                 # Test suite
├── docker/                    # Docker configurations
├── scripts/                   # Automation scripts
└── docker-compose.yml         # Container orchestration
```

## Quick Start

### Prerequisites

- Python 3.9+
- Docker & Docker Compose
- Make

### 1. Setup Environment

```bash
# Clone the repository
git clone <repository-url>
cd itesm-cicd-demo

# Setup virtual environment and dependencies
make setup
```

### 2. Train and Test v1 Model

```bash
# Train the v1 model (poor performance by design)
make train-v1

# Test the v1 model locally
make test-v1

# Run all v1 tests
make check-v1
```

### 3. Run Local Development

```bash
# Start development server
make dev

# Visit: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

### 4. Docker Deployment

```bash
# Build and test in Docker
make test-docker-v1

# Run in Docker
make run-v1

# Full Docker deployment pipeline
make deploy-docker-v1
```

## Available Commands

### Model Training & Testing

```bash
make train-v1        # Train v1 model
make test-v1         # Test v1 model pipeline
make test-v1-only    # Test only v1 API functionality
make check-v1        # Comprehensive v1 validation
```

### Docker Operations

```bash
make build-v1        # Build v1 Docker images
make test-docker-v1  # Test v1 in Docker environment
make run-v1          # Run v1 services
make docker-dev      # Development mode with hot reload
make docker-logs     # View container logs
make docker-clean-v1 # Clean v1 Docker resources
```

### Development

```bash
make install         # Setup virtual environment
make setup           # Initial project setup
make dev             # Start development server
make test-local      # Run local tests
make test-quick      # Quick pytest run
```

### Production

```bash
make prod-build      # Build production image
make prod-test       # Test production build
make deploy-v1       # Full v1 deployment pipeline
```

### Cleanup

```bash
make clean-models    # Remove model files
make clean-all       # Clean everything
make help            # Show all available commands
```

## Model Performance

### v1 Model (Current)

- **Algorithm**: Decision Tree Classifier
- **Performance**: ~50-70% accuracy (deliberately poor)
- **Purpose**: Baseline model for CI/CD demonstration
- **Features**: Basic classification with minimal parameters

### v2 Model (Coming Soon)

- **Algorithm**: Random Forest Classifier
- **Expected Performance**: ~95%+ accuracy
- **Purpose**: Demonstrate model improvement through CI/CD
- **Features**: Optimized hyperparameters and ensemble methods

## API Endpoints

### Health & Status

- `GET /` - Root endpoint with API information
- `GET /health` - Health check and model status
- `GET /model-info` - Detailed model information

### Predictions

- `GET /predict` - Main prediction endpoint (uses active model)
- `GET /predict/v1` - Specific v1 model prediction

Example prediction request:

```bash
curl "http://localhost:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
```

Example response:

```json
{
  "model": "v1",
  "prediction": "setosa",
  "accuracy": 0.633,
  "model_type": "DecisionTreeClassifier"
}
```

## Testing Strategy

### Local Testing

```bash
# Unit tests for training pipeline
PYTHONPATH=. pytest src/tests/test_training.py -v

# API endpoint tests
PYTHONPATH=. pytest src/tests/test_api.py -v

# v1 specific tests
make test-v1-only
```

### Docker Testing

```bash
# Full Docker pipeline test
make test-docker-v1

# Check Docker logs
make docker-logs
```

### Integration Testing

- API health checks
- Model loading validation
- Prediction accuracy tests
- Error handling verification

## Docker Configuration

### Services

- **training**: Trains the ML model and saves to shared volume
- **api**: Serves the trained model via FastAPI

### Volumes

- `./src/api/models:/app/src/api/models` - Shared model storage
- `./model_registry.json:/app/model_registry.json` - Model metadata

### Environment Variables

- `PYTHONPATH=/app` - Python path configuration
- `MODEL_VERSION=v1` - Active model version
- `PORT=8000` - API server port

## CI/CD Workflow

### Current State (v1)

1. **Train** poor-performing model (baseline)
2. **Test** model functionality and API
3. **Deploy** to production environment
4. **Monitor** performance metrics

### Next Release (v2)

1. **Improve** model with better algorithm
2. **Validate** performance improvement
3. **Deploy** enhanced model
4. **Compare** v1 vs v2 performance

## Development Workflow

### Adding New Features

1. Create feature branch
2. Implement changes
3. Run tests: `make test-all`
4. Test in Docker: `make test-docker-v1`
5. Submit pull request

### Model Updates

1. Update training pipeline in `src/training/pipelines/`
2. Run training: `make train-v1`
3. Test model: `make test-v1`
4. Validate API: `make check-v1`

## Troubleshooting

### Common Issues

**Makefile errors:**

```bash
# Ensure using tabs, not spaces for indentation
make help
```

**Docker build fails:**

```bash
# Clean and rebuild
make docker-clean-v1
make build-v1
```

**Model not found:**

```bash
# Retrain model
make clean-models
make train-v1
```

**Port already in use:**

```bash
# Check running processes
lsof -i :8000
# Kill if necessary
make docker-clean-v1
```

### Health Checks

```bash
# Check API health
curl http://localhost:8000/health

# Check model status
curl http://localhost:8000/model-info

# Test prediction
curl "http://localhost:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
```

## Model Registry

The `model_registry.json` file tracks model metadata:

```json
{
  "active_model": "iris_v1.pkl",
  "metrics": {
    "accuracy": 0.633
  },
  "version": "v1",
  "model_type": "DecisionTreeClassifier"
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `make test-all`
4. Submit a pull request

## License

This project is for educational purposes, demonstrating ML CI/CD best practices.

---

**Current Status**: v1 Model Deployed | v2 Model In Development

**API URL**: `http://localhost:8000` | **Docs**: `http://localhost:8000/docs`
