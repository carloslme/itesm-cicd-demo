.PHONY: help setup clean train-v1 train-v2 test-local test-v1 test-v2 run-api build run-docker docker-v1 docker-v2 docker-compare demo-docker-cicd create-ec2 deploy-to-ec2 deploy-v2 test-ec2 connect-ec2 destroy-ec2 demo-cicd compare-models ec2-full

# Default target
help:
	@echo "Available targets:"
	@echo "  setup           - Set up Python virtual environment"
	@echo "  clean           - Clean up generated files and containers"
	@echo ""
	@echo "Model Training:"
	@echo "  train-v1        - Train v1 model (poor performance)"
	@echo "  train-v2        - Train v2 model (high performance)"
	@echo "  train-both      - Train both model versions"
	@echo ""
	@echo "Testing:"
	@echo "  test-local      - Run all local tests"
	@echo "  test-v1         - Test v1 model specifically"
	@echo "  test-v2         - Test v2 model specifically"
	@echo "  test-api        - Test API endpoints"
	@echo ""
	@echo "Local Development:"
	@echo "  run-api         - Run API server locally"
	@echo "  run-api-v1      - Run API with v1 model"
	@echo "  run-api-v2      - Run API with v2 model"
	@echo ""
	@echo "Docker:"
	@echo "  build           - Build Docker image"
	@echo "  docker-v1       - Run v1 model with Docker"
	@echo "  docker-v2       - Run v2 model with Docker"
	@echo "  docker-compare  - Run side-by-side comparison"
	@echo "  demo-docker-cicd - Complete Docker CI/CD demo"
	@echo ""
	@echo "AWS EC2:"
	@echo "  create-ec2      - Create EC2 instance"
	@echo "  deploy-to-ec2   - Deploy current model to EC2"
	@echo "  deploy-v2       - Deploy v2 model to EC2"
	@echo "  test-ec2        - Test deployed API on EC2"
	@echo "  connect-ec2     - SSH connect to EC2 instance"
	@echo "  destroy-ec2     - Terminate EC2 instance"
	@echo ""
	@echo "CI/CD Demo:"
	@echo "  demo-cicd       - Complete EC2 CI/CD demonstration"
	@echo "  compare-models  - Compare v1 vs v2 performance"
	@echo "  ec2-full        - Complete EC2 workflow"

# Python environment setup
setup:
	@echo "Setting up Python virtual environment..."
	python3 -m venv .venv
	@echo "Installing dependencies..."
	.venv/bin/pip install --upgrade pip
	.venv/bin/pip install -r requirements.txt
	@echo "Setup complete! Activate with: source .venv/bin/activate"

# Model training targets
train-v1:
	@echo "Training v1 model (poor performance baseline)..."
	python3 src/training/train.py 1
	@echo "v1 training complete"

train-v2:
	@echo "Training v2 model (high performance)..."
	python3 src/training/train.py 2
	@echo "v2 training complete"

train-both:
	@echo "Training both model versions..."
	make train-v1
	make train-v2
	@echo "Both models trained successfully"

# Testing targets
test-local:
	@echo "Running all local tests..."
	export PYTHONPATH=$$PWD && pytest src/tests/ -v

test-v1:
	@echo "Testing v1 model..."
	export PYTHONPATH=$$PWD && pytest src/tests/test_model_v1.py -v

test-v2:
	@echo "Testing v2 model..."
	export PYTHONPATH=$$PWD && pytest src/tests/test_model_v2.py -v

test-api:
	@echo "Testing API endpoints..."
	export PYTHONPATH=$$PWD && pytest src/tests/test_api.py -v

# Local API development
run-api:
	@echo "Starting API server locally..."
	uvicorn src.api.main:app --reload --host 0.0.0.0 --port 8000

run-api-v1:
	@echo "Starting API with v1 model..."
	make train-v1
	MODEL_VERSION=v1 uvicorn src.api.main:app --reload --host 0.0.0.0 --port 8000

run-api-v2:
	@echo "Starting API with v2 model..."
	make train-v2
	MODEL_VERSION=v2 uvicorn src.api.main:app --reload --host 0.0.0.0 --port 8000

# Docker targets
build:
	@echo "Building Docker image..."
	docker build -f docker/api.Dockerfile -t iris-ml-api .

build-no-cache:
	@echo "Building Docker image without cache..."
	docker build --no-cache -f docker/api.Dockerfile -t iris-ml-api .

docker-v1:
	@echo "Starting v1 model (baseline performance)..."
	MODEL_VERSION=v1 docker-compose up --build

docker-v2:
	@echo "Starting v2 model (improved performance)..."
	MODEL_VERSION=v2 docker-compose up --build

docker-compare:
	@echo "Starting side-by-side comparison..."
	MODEL_VERSION=v1 COMPARE_MODEL_VERSION=v2 docker-compose --profile compare up -d --build
	sleep 10
	@echo ""
	@echo "Services started:"
	@echo "  v1 model: http://localhost:8000"
	@echo "  v2 model: http://localhost:8001"
	@echo ""
	@echo "Test commands:"
	@echo "  curl http://localhost:8000/model-info"
	@echo "  curl http://localhost:8001/model-info"
	@echo ""
	@echo "Compare predictions:"
	@echo "  curl \"http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2\""
	@echo "  curl \"http://localhost:8001/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2\""
	@echo ""
	@echo "Stop with: make docker-stop"

demo-docker-cicd:
	@echo "=== Docker CI/CD Demo ==="
	@echo ""
	@echo "Step 1: Starting with v1 (poor performance baseline)..."
	MODEL_VERSION=v1 docker-compose up -d --build
	@echo "Waiting for service to start..."
	sleep 15
	@echo ""
	@echo "Current model performance:"
	curl -s http://localhost:8000/model-info | jq || curl -s http://localhost:8000/model-info
	@echo ""
	@echo "Sample prediction with v1:"
	curl -s "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2" | jq || curl -s "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
	@echo ""
	@echo "Step 2: Deploying v2 (major improvement)..."
	@echo "Stopping v1 service..."
	docker-compose down
	@echo "Starting v2 service..."
	MODEL_VERSION=v2 docker-compose up -d --build
	@echo "Waiting for v2 service to start..."
	sleep 15
	@echo ""
	@echo "New model performance:"
	curl -s http://localhost:8000/model-info | jq || curl -s http://localhost:8000/model-info
	@echo ""
	@echo "Same prediction with improved v2 model:"
	curl -s "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2" | jq || curl -s "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
	@echo ""
	@echo "=== CI/CD Demo Complete: v1 seamlessly replaced by v2! ==="
	@echo "Same endpoint, dramatically improved performance!"
	docker-compose down

docker-stop:
	@echo "Stopping all docker-compose services..."
	docker-compose down
	docker-compose --profile compare down

# EC2 deployment targets
create-ec2:
	@echo "Creating EC2 instance..."
	bash scripts/create_ec2_instance.sh

deploy-to-ec2:
	@echo "Deploying to EC2..."
	bash scripts/deploy_to_ec2.sh

deploy-v1-to-ec2:
	@echo "Deploying v1 model to EC2..."
	make train-v1
	bash scripts/deploy_to_ec2.sh

deploy-v2:
	@echo "Deploying v2 model (demonstrating CI/CD improvement)..."
	MODEL_VERSION=v2 bash scripts/deploy_to_ec2.sh
	@echo "v2 deployment complete - performance dramatically improved!"

test-ec2:
	@echo "Testing deployed API on EC2..."
	@if [ ! -f "ec2-instance-info.txt" ]; then \
		echo "Error: EC2 instance info not found. Run 'make create-ec2' first."; \
		exit 1; \
	fi
	@PUBLIC_IP=$$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3); \
	echo "Testing API at: $$PUBLIC_IP:8000"; \
	echo ""; \
	echo "Health check:"; \
	curl -f "http://$$PUBLIC_IP:8000/health" && echo " - OK" || echo " - FAILED"; \
	echo ""; \
	echo "Model info:"; \
	curl -s "http://$$PUBLIC_IP:8000/model-info" | jq || curl -s "http://$$PUBLIC_IP:8000/model-info"; \
	echo ""; \
	echo "Prediction test:"; \
	curl -s "http://$$PUBLIC_IP:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2" | jq || curl -s "http://$$PUBLIC_IP:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"

connect-ec2:
	@echo "Connecting to EC2 instance..."
	@if [ ! -f "ec2-instance-info.txt" ]; then \
		echo "Error: EC2 instance info not found. Run 'make create-ec2' first."; \
		exit 1; \
	fi
	@PUBLIC_IP=$$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3); \
	KEY_FILE=$$(grep "Key File:" ec2-instance-info.txt | cut -d' ' -f3); \
	echo "Connecting to: $$PUBLIC_IP"; \
	ssh -i $$KEY_FILE ec2-user@$$PUBLIC_IP

logs-ec2:
	@echo "Viewing EC2 API logs..."
	@if [ ! -f "ec2-instance-info.txt" ]; then \
		echo "Error: EC2 instance info not found."; \
		exit 1; \
	fi
	@PUBLIC_IP=$$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3); \
	KEY_FILE=$$(grep "Key File:" ec2-instance-info.txt | cut -d' ' -f3); \
	ssh -i $$KEY_FILE ec2-user@$$PUBLIC_IP 'tail -f app/api.log'

destroy-ec2:
	@echo "Terminating EC2 instance..."
	@if [ ! -f "ec2-instance-info.txt" ]; then \
		echo "Error: EC2 instance info not found."; \
		exit 1; \
	fi
	@INSTANCE_ID=$$(grep "Instance ID:" ec2-instance-info.txt | cut -d' ' -f3); \
	echo "Terminating instance: $$INSTANCE_ID"; \
	aws ec2 terminate-instances --instance-ids $$INSTANCE_ID; \
	echo "Instance termination initiated. Cleaning up local files..."; \
	rm -f ec2-instance-info.txt *.pem

# CI/CD demonstration targets
demo-cicd:
	@echo "=== Complete EC2 CI/CD Demo Workflow ==="
	@echo ""
	@echo "Step 1: Current v1 performance (~30% accuracy)"
	@if [ ! -f "ec2-instance-info.txt" ]; then \
		echo "Error: No EC2 instance found. Run 'make create-ec2' first."; \
		exit 1; \
	fi
	@PUBLIC_IP=$$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3); \
	echo "Current model info:"; \
	curl -s "http://$$PUBLIC_IP:8000/model-info" | jq || curl -s "http://$$PUBLIC_IP:8000/model-info"
	@echo ""
	@echo "Step 2: Deploying improved v2 model..."
	@make deploy-v2
	@echo ""
	@echo "Step 3: New v2 performance (95%+ accuracy)"
	@PUBLIC_IP=$$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3); \
	echo "Updated model info:"; \
	curl -s "http://$$PUBLIC_IP:8000/model-info" | jq || curl -s "http://$$PUBLIC_IP:8000/model-info"
	@echo ""
	@echo "=== CI/CD Demo Complete: Dramatic improvement achieved! ==="

compare-models:
	@echo "=== Comparing v1 vs v2 Model Performance ==="
	@if [ ! -f "ec2-instance-info.txt" ]; then \
		echo "Error: No EC2 instance found."; \
		exit 1; \
	fi
	@PUBLIC_IP=$$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3); \
	echo "Testing same input on both models:"; \
	echo "Input: sepal_length=5.1, sepal_width=3.5, petal_length=1.4, petal_width=0.2"; \
	echo ""; \
	echo "v1 result (poor performance):"; \
	curl -s "http://$$PUBLIC_IP:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2" | jq || curl -s "http://$$PUBLIC_IP:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"; \
	echo ""; \
	echo "v2 result (high performance):"; \
	curl -s "http://$$PUBLIC_IP:8000/predict/v2?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2" | jq || curl -s "http://$$PUBLIC_IP:8000/predict/v2?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"

# Model switching (for runtime testing)
switch-to-v1:
	@echo "Switching active model to v1..."
	curl -X POST "http://localhost:8000/switch-model?target_version=v1" | jq || curl -X POST "http://localhost:8000/switch-model?target_version=v1"

switch-to-v2:
	@echo "Switching active model to v2..."
	curl -X POST "http://localhost:8000/switch-model?target_version=v2" | jq || curl -X POST "http://localhost:8000/switch-model?target_version=v2"

# Complete workflows
ec2-full:
	@echo "=== Complete EC2 Deployment Workflow ==="
	@echo "Step 1: Creating EC2 instance..."
	make create-ec2
	@echo "Step 2: Waiting for instance to be ready..."
	sleep 60
	@echo "Step 3: Deploying v1 model..."
	make deploy-v1-to-ec2
	@echo "Step 4: Testing deployment..."
	make test-ec2
	@echo "Step 5: Deploying v2 for comparison..."
	make deploy-v2
	@echo "Step 6: Comparing models..."
	make compare-models
	@echo "=== EC2 deployment workflow completed ==="

local-full:
	@echo "=== Complete Local Development Workflow ==="
	@echo "Step 1: Training both models..."
	make train-both
	@echo "Step 2: Running tests..."
	make test-local
	@echo "Step 3: Building Docker image..."
	make build
	@echo "Step 4: Running Docker CI/CD demo..."
	make demo-docker-cicd
	@echo "=== Local workflow completed ==="

# Quick testing shortcuts
quick-test-local:
	@echo "Quick local API test..."
	@if ! pgrep -f "uvicorn.*main:app" > /dev/null; then \
		echo "Starting API in background..."; \
		nohup make run-api > api.log 2>&1 & \
		sleep 5; \
	fi
	@echo "Testing endpoints:"
	@curl -s http://localhost:8000/health | jq || curl -s http://localhost:8000/health
	@curl -s http://localhost:8000/model-info | jq || curl -s http://localhost:8000/model-info

quick-test-docker:
	@echo "Quick Docker test..."
	MODEL_VERSION=v2 docker-compose up -d --build
	sleep 10
	curl -s http://localhost:8000/model-info | jq || curl -s http://localhost:8000/model-info
	docker-compose down

# Monitoring and debugging
status:
	@echo "=== Current Project Status ==="
	@echo "Models:"
	@if [ -f "src/api/models/iris_v1.pkl" ]; then echo "  v1: Available"; else echo "  v1: Not found"; fi
	@if [ -f "src/api/models/iris_v2.pkl" ]; then echo "  v2: Available"; else echo "  v2: Not found"; fi
	@echo "Registry:"
	@if [ -f "model_registry.json" ]; then cat model_registry.json | jq || cat model_registry.json; else echo "  Not found"; fi
	@echo "EC2:"
	@if [ -f "ec2-instance-info.txt" ]; then \
		echo "  Instance: $$(grep 'Instance ID:' ec2-instance-info.txt | cut -d' ' -f3)"; \
		echo "  Public IP: $$(grep 'Public IP:' ec2-instance-info.txt | cut -d' ' -f3)"; \
	else echo "  No instance configured"; fi
	@echo "Docker:"
	@docker ps --filter "name=iris" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "  No containers running"

# Validation targets
validate-ec2:
	@echo "Validating EC2 deployment..."
	@if [ ! -f "ec2-instance-info.txt" ]; then \
		echo "Error: No EC2 instance configured"; \
		exit 1; \
	fi
	@PUBLIC_IP=$$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3); \
	echo "Checking instance: $$PUBLIC_IP"; \
	curl -f "http://$$PUBLIC_IP:8000/health" > /dev/null && echo "Instance is healthy" || echo "Instance is not responding"

validate-models:
	@echo "Validating trained models..."
	@if [ ! -f "src/api/models/iris_v1.pkl" ]; then echo "Error: v1 model not found"; exit 1; fi
	@if [ ! -f "src/api/models/iris_v2.pkl" ]; then echo "Error: v2 model not found"; exit 1; fi
	@if [ ! -f "model_registry.json" ]; then echo "Error: model registry not found"; exit 1; fi
	@echo "All models and registry files are present"

# Cleanup targets
clean:
	@echo "Cleaning up generated files..."
	rm -rf .venv
	rm -rf __pycache__
	rm -rf src/**/__pycache__
	rm -rf .pytest_cache
	rm -rf src/api/models/*.pkl
	rm -f model_registry.json
	rm -f *.log

clean-docker:
	@echo "Cleaning up Docker resources..."
	docker-compose down || true
	docker-compose --profile compare down || true
	docker container prune -f
	docker image prune -f
	docker system prune -f

clean-all: clean clean-docker
	@echo "Complete cleanup finished"

# Development helpers
dev-setup: setup train-both
	@echo "Development environment ready!"
	@echo "Available commands:"
	@echo "  make run-api           - Start local API"
	@echo "  make test-local        - Run tests"
	@echo "  make demo-docker-cicd  - Docker CI/CD demo"
	@echo "  make status            - Check current status"

# Help for specific workflows
help-docker:
	@echo "Docker CI/CD Workflow:"
	@echo "  1. make docker-v1        - Start with baseline v1"
	@echo "  2. make docker-v2        - Upgrade to improved v2"
	@echo "  3. make demo-docker-cicd - Complete replacement demo"
	@echo "  4. make docker-compare   - Side-by-side comparison"

help-ec2:
	@echo "EC2 CI/CD Workflow:"
	@echo "  1. make create-ec2       - Create new EC2 instance"
	@echo "  2. make deploy-to-ec2    - Deploy v1 model"
	@echo "  3. make deploy-v2        - Upgrade to v2 model"
	@echo "  4. make compare-models   - Compare performance"
	@echo "  5. make destroy-ec2      - Clean up instance"

help-dev:
	@echo "Development Workflow:"
	@echo "  1. make setup            - Set up environment"
	@echo "  2. make train-both       - Train both models"
	@echo "  3. make run-api          - Start local API"
	@echo "  4. make test-local       - Run tests"
	@echo "  5. make status           - Check current status"

# Add this new target to fix model issues
reset-models:
	@echo "🔄 Resetting all models and registry..."
	@echo "Cleaning existing models and registry..."
	rm -f src/api/models/*.pkl
	rm -f model_registry.json
	@echo "Training v1 model (poor performance)..."
	python3 src/training/train.py 1
	@echo "✅ v1 model reset complete"
	@echo ""
	@echo "Current model status:"
	@if [ -f "model_registry.json" ]; then cat model_registry.json | jq || cat model_registry.json; fi

reset-and-train-both:
	@echo "🔄 Resetting and training both models..."
	make reset-models
	@echo ""
	@echo "Training v2 model (high performance)..."
	python3 src/training/train.py 2
	@echo "✅ Both models reset and trained"
	@echo ""
	@echo "Final model status:"
	@if [ -f "model_registry.json" ]; then cat model_registry.json | jq || cat model_registry.json; fi
