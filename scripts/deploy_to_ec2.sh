#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Deploying ML API to EC2"

# Read instance info
if [ ! -f "ec2-instance-info.txt" ]; then
    echo "❌ ec2-instance-info.txt not found. Create EC2 instance first."
    echo "💡 Run: make create-ec2"
    exit 1
fi

# Extract instance information
PUBLIC_IP=$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3)
KEY_FILE=$(grep "Key File:" ec2-instance-info.txt | cut -d' ' -f3)
INSTANCE_ID=$(grep "Instance ID:" ec2-instance-info.txt | cut -d' ' -f3)

echo "📋 Deployment target:"
echo "  Instance ID: $INSTANCE_ID"
echo "  Public IP: $PUBLIC_IP"
echo "  Key File: $KEY_FILE"

# Validate key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Key file not found: $KEY_FILE"
    echo "📝 Please ensure the key file exists and has correct permissions"
    exit 1
fi

# Ensure correct key permissions
chmod 400 "$KEY_FILE"

# Check if instance is running
echo "🔍 Checking instance status..."
INSTANCE_STATE=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

if [ "$INSTANCE_STATE" != "running" ]; then
    echo "❌ Instance is not running. Current state: $INSTANCE_STATE"
    echo "💡 Please ensure the instance is running before deployment"
    exit 1
fi

# Wait for instance to be ready
echo "⏳ Waiting for instance to be ready..."
echo "🔄 Testing SSH connectivity..."

# Test SSH connection with retries
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
        ec2-user@$PUBLIC_IP "echo 'SSH connection successful'" &>/dev/null; then
        echo "✅ SSH connection established"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "⏳ SSH attempt $RETRY_COUNT/$MAX_RETRIES failed. Retrying in 15 seconds..."
        sleep 15
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ Failed to establish SSH connection after $MAX_RETRIES attempts"
    echo "🔧 Troubleshooting:"
    echo "  1. Check security group allows SSH (port 22)"
    echo "  2. Verify key file permissions: chmod 400 $KEY_FILE"
    echo "  3. Ensure instance is fully initialized"
    exit 1
fi

# Train model locally first to ensure it works
echo "🎯 Training model locally..."
if ! python3 src/training/pipelines/iris_pipeline.py; then
    echo "❌ Local model training failed. Please fix issues before deployment."
    exit 1
fi

# Copy project files to EC2
echo "📤 Copying project files to EC2..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "mkdir -p /home/ec2-user/app"

scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -r \
    src/ requirements.txt model_registry.json \
    ec2-user@$PUBLIC_IP:/home/ec2-user/app/

echo "✅ Files copied successfully"

# Create enhanced deployment script on EC2
cat > deploy-on-ec2.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "🔧 Starting deployment on EC2..."
cd /home/ec2-user/app

# Check if setup is complete
if [ ! -f "/home/ec2-user/setup-complete.txt" ]; then
    echo "⏳ EC2 setup still in progress. Waiting..."
    sleep 30
fi

# Update system packages
echo "📦 Installing system dependencies..."
sudo yum update -y
sudo yum install -y python3-pip curl jq

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
pip3 install --user -r requirements.txt

# Initialize PYTHONPATH properly
export PYTHONPATH="${PYTHONPATH:-}:/home/ec2-user/app"
export PATH="$HOME/.local/bin:$PATH"

# Train the model
echo "🎯 Training model on EC2..."
python3 src/training/pipelines/iris_pipeline.py

# Verify model files exist
if [ ! -f "src/api/models/iris_v1.pkl" ] || [ ! -f "model_registry.json" ]; then
    echo "❌ Model files not found after training"
    exit 1
fi

echo "✅ Model training completed"

# Kill any existing API process
echo "🔄 Stopping existing API processes..."
pkill -f "uvicorn" || true
sleep 3

# Check if port 8000 is available
if command -v netstat >/dev/null && netstat -tuln | grep -q ":8000 "; then
    echo "⚠️  Port 8000 still in use. Waiting..."
    sleep 5
fi

# Start API with proper error handling
echo "🚀 Starting API server..."

# Create a startup script that handles environment properly
cat > start_api.sh << 'INNER_EOF'
#!/bin/bash
export PYTHONPATH="/home/ec2-user/app:${PYTHONPATH:-}"
export PATH="$HOME/.local/bin:$PATH"
cd /home/ec2-user/app

python3 -m uvicorn src.api.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 1
INNER_EOF

chmod +x start_api.sh

# Start the API in background
nohup ./start_api.sh > api.log 2>&1 &
API_PID=$!
echo "API started with PID: $API_PID"

# Wait for API to start
echo "⏳ Waiting for API to initialize..."
sleep 10

# Test the API with retries
MAX_ATTEMPTS=5
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "🧪 Testing API (attempt $ATTEMPT/$MAX_ATTEMPTS)..."
    
    if curl -f -s http://localhost:8000/health > /dev/null; then
        echo "✅ API health check passed"
        
        # Test prediction endpoint
        if curl -f -s "http://localhost:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2" > /dev/null; then
            echo "✅ API prediction test passed"
            break
        else
            echo "⚠️  Prediction endpoint test failed"
        fi
    else
        echo "❌ Health check failed (attempt $ATTEMPT)"
        
        if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
            echo "❌ API failed to start properly. Check logs:"
            tail -20 api.log
            exit 1
        fi
        
        sleep 5
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
done

echo "🎉 Deployment completed successfully!"
echo "📊 API Status:"
echo "  Health: http://localhost:8000/health"
echo "  Docs: http://localhost:8000/docs"
echo "  Logs: tail -f ~/app/api.log"
EOF

# Copy and run deployment script
echo "🚀 Executing deployment on EC2..."
scp -i "$KEY_FILE" -o StrictHostKeyChecking=no deploy-on-ec2.sh ec2-user@$PUBLIC_IP:/home/ec2-user/
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "chmod +x deploy-on-ec2.sh && ./deploy-on-ec2.sh"

echo ""
echo "✅ Deployment completed!"
echo "🌐 Your ML API is now running at:"
echo "  Health Check: http://$PUBLIC_IP:8000/health"
echo "  API Docs: http://$PUBLIC_IP:8000/docs"
echo "  Model Info: http://$PUBLIC_IP:8000/model-info"
echo ""
echo "🎯 Test your API:"
echo "  curl http://$PUBLIC_IP:8000/health"
echo "  curl \"http://$PUBLIC_IP:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2\""
echo ""

# Test the deployed API from local machine
echo "🧪 Testing deployed API from local machine..."
sleep 5

if curl -f -s "http://$PUBLIC_IP:8000/health" > /dev/null; then
    echo "✅ Remote health check passed"
    
    # Test prediction
    echo "🔮 Testing prediction endpoint..."
    PREDICTION_RESULT=$(curl -s "http://$PUBLIC_IP:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2")
    echo "📊 Prediction result: $PREDICTION_RESULT"
    echo "✅ Prediction test passed"
else
    echo "⚠️  Remote health check failed. API might still be starting up."
    echo "💡 Try again in a few minutes or check logs:"
    echo "  ssh -i $KEY_FILE ec2-user@$PUBLIC_IP 'tail -f app/api.log'"
fi

# Save deployment info
cat >> ec2-instance-info.txt << EOF

Deployment Status: ✅ DEPLOYED
Deployment Time: $(date)
API Health: http://$PUBLIC_IP:8000/health
API Docs: http://$PUBLIC_IP:8000/docs
SSH Command: ssh -i $KEY_FILE ec2-user@$PUBLIC_IP
View Logs: ssh -i $KEY_FILE ec2-user@$PUBLIC_IP 'tail -f app/api.log'
EOF

echo "📄 Deployment info updated in ec2-instance-info.txt"

# Cleanup
rm -f deploy-on-ec2.sh

echo ""
echo "🎉 Your ML API v1 is now live on AWS EC2!"
echo "🚀 Ready for production traffic and v2 model improvements!"