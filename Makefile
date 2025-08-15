.PHONY: v1 v2 clean help

v1:
	@echo "🚀 Starting v1 (poor model)..."
	docker-compose down
	MODEL_VERSION=v1 docker-compose up --build

v2:
	@echo "🚀 Starting v2 (good model)..."
	docker-compose down
	MODEL_VERSION=v2 docker-compose up --build

clean:
	@echo "🧹 Cleaning everything..."
	docker-compose down
	docker system prune -f

help:
	@echo "Commands:"
	@echo "  make v1    - Run v1 model (33% accuracy)"
	@echo "  make v2    - Run v2 model (90% accuracy)"
	@echo "  make clean - Clean everything"