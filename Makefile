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

reate-ec2:
	@echo "🚀 Creating EC2 instance..."
	./scripts/create_ec2_instance.sh

deploy-v1-to-ec2:
	@echo "🚀 Deploying v1 model to EC2..."
	MODEL_VERSION=v1 ./scripts/deploy_to_ec2.sh

deploy-v2-to-ec2:
	@echo "🚀 Deploying v2 model to EC2..."
	MODEL_VERSION=v2 ./scripts/deploy_to_ec2.sh

test-ec2:
	@echo "🧪 Testing EC2 deployment..."
	@if [ -f "ec2-instance-info.txt" ]; then \
		PUBLIC_IP=$$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3); \
		echo "Testing API at http://$$PUBLIC_IP:8000"; \
		curl "http://$$PUBLIC_IP:8000/health" && \
		curl "http://$$PUBLIC_IP:8000/model-info" && \
		curl "http://$$PUBLIC_IP:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"; \
	else \
		echo "❌ No EC2 instance found. Run 'make create-ec2' first."; \
	fi

destroy-ec2:
	@echo "🧹 Destroying EC2 instance..."
	@if [ -f "ec2-instance-info.txt" ]; then \
		INSTANCE_ID=$$(grep "Instance ID:" ec2-instance-info.txt | cut -d' ' -f3); \
		aws ec2 terminate-instances --instance-ids $$INSTANCE_ID; \
		echo "✅ Instance $$INSTANCE_ID terminated"; \
		rm -f ec2-instance-info.txt; \
	else \
		echo "❌ No instance info found"; \
	fi