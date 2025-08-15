# Makefile for ML CI/CD Demo

.PHONY: build api training run clean test-local test-quick train-and-test api-test test-docker test-docker-logs test-docker-clean train-v1 test-v1 deploy-v1 check-v1 test-v1-only build-v1 test-docker-v1 run-v1 deploy-docker-v1 docker-dev docker-logs docker-clean-v1 help

# Build the Docker images for API and Training
build:
	docker-compose build

# Run the API service
api:
	docker-compose up api

# Run the Training service
training:
	docker-compose up training

# Run all services
run:
	docker-compose up

# Clean up Docker containers and images
clean:
	docker-compose down --rmi all

# Local testing targets
test-local:
	bash scripts/test_local.sh

test-quick:
	PYTHONPATH=. pytest -q

train-and-test:
	python src/training/pipelines/iris_pipeline.py && PYTHONPATH=. pytest -q

api-test:
	uvicorn src.api.main:app --reload &
	sleep 3 && curl http://localhost:8000/health

# Docker testing targets
test-docker:
	bash scripts/test_docker.sh

test-docker-logs:
	docker compose logs

test-docker-clean:
	docker compose down --remove-orphans --volumes

# v1 Model specific targets
train-v1:
	python src/training/pipelines/iris_pipeline.py

test-v1:
	bash scripts/test_v1.sh

deploy-v1:
	@echo "🚀 Deploying v1 model to production"
	make train-v1
	make test-v1
	@echo "✅ v1 ready for deployment"

test-v1-only:
	PYTHONPATH=. pytest src/tests/test_api_v1.py -v

check-v1:
	PYTHONPATH=. pytest src/tests/test_api.py -v -k "not v2"
	@echo "✅ v1 tests completed"

# Docker v1 specific targets
build-v1:
	docker compose build

test-docker-v1:
	bash scripts/test_docker_v1.sh

run-v1:
	docker compose up

deploy-docker-v1:
	@echo "🚀 Deploying v1 in Docker"
	make build-v1
	make test-docker-v1
	@echo "✅ Docker v1 deployment ready"

docker-dev:
	docker compose up --build

docker-logs:
	docker compose logs -f

docker-clean-v1:
	docker compose down --remove-orphans --volumes
	docker system prune -f

# Development workflow targets
install:
	python -m venv .venv
	source .venv/bin/activate && pip install -r requirements.txt

setup:
	make install
	mkdir -p src/api/models
	mkdir -p scripts

dev:
	source .venv/bin/activate && uvicorn src.api.main:app --reload --host 0.0.0.0 --port 8000

# Testing workflow
test-all:
	make test-quick
	make test-local
	make test-docker

# Production deployment helpers
prod-build:
	docker build -t iris-ml-api:latest .

prod-test:
	docker run -d -p 8000:8000 --name iris-test iris-ml-api:latest
	sleep 10
	curl -f http://localhost:8000/health || echo "Health check failed"
	docker stop iris-test && docker rm iris-test

# Cleanup targets
clean-models:
	rm -f model_registry.json
	rm -f src/api/models/iris_v*.pkl

clean-all:
	make clean
	make clean-models
	docker system prune -f

# Help target
help:
	@echo "Available targets:"
	@echo "  build         - Build Docker images"
	@echo "  api           - Run API service"
	@echo "  training      - Run training service"
	@echo "  run           - Run all services"
	@echo "  clean         - Clean Docker containers and images"
	@echo ""
	@echo "Testing:"
	@echo "  test-local    - Run local tests"
	@echo "  test-quick    - Run quick pytest"
	@echo "  test-docker   - Run Docker tests"
	@echo "  test-all      - Run all tests"
	@echo ""
	@echo "v1 Model:"
	@echo "  train-v1      - Train v1 model"
	@echo "  test-v1       - Test v1 model"
	@echo "  deploy-v1     - Deploy v1 model"
	@echo "  check-v1      - Check v1 model status"
	@echo "  test-v1-only  - Test only v1 functionality"
	@echo ""
	@echo "Docker v1:"
	@echo "  build-v1      - Build v1 Docker images"
	@echo "  test-docker-v1 - Test v1 in Docker"
	@echo "  run-v1        - Run v1 Docker services"
	@echo "  deploy-docker-v1 - Deploy v1 Docker pipeline"
	@echo "  docker-dev    - Run Docker in development mode"
	@echo "  docker-logs   - Show Docker logs"
	@echo "  docker-clean-v1 - Clean v1 Docker resources"
	@echo ""
	@echo "Development:"
	@echo "  install       - Setup virtual environment"
	@echo "  setup         - Initial project setup"
	@echo "  dev           - Start development server"
	@echo ""
	@echo "Production:"
	@echo "  prod-build    - Build production image"
	@echo "  prod-test     - Test production build"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean-models  - Remove model files"
	@echo "  clean-all     - Clean everything"
	@echo ""
	@echo "  help          - Show this help message"