# 🚀 ML CI/CD Demo - Iris Classification

Simple Docker demo: v1 (33% accuracy) → v2 (90% accuracy)

## 🎯 Quick Demo

### Test v1 (Poor Model)
```bash
make v1
# Wait for "Uvicorn running on http://0.0.0.0:8000"
```

**Test:**
```bash
curl http://localhost:8000/model-info
curl "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
```

### Test v2 (Good Model)
```bash
make v2
# Wait for "Uvicorn running on http://0.0.0.0:8000"
```

**Test:**
```bash
curl http://localhost:8000/model-info
curl "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
```

## 📊 Expected Results

**v1:** DummyClassifier, 33% accuracy, random predictions
**v2:** RandomForestClassifier, 90% accuracy, smart predictions

## ☁️ AWS EC2 Deployment

### Prerequisites for EC2 Deployment

```bash
# 1. Install and configure AWS CLI
pip install awscli
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format

# 2. Verify AWS configuration
aws sts get-caller-identity
aws ec2 describe-regions --output table
```

### Step 1: Create EC2 Instance

```bash
# Create EC2 instance
make create-ec2
```

**Expected output:**
```
✅ EC2 instance created successfully!
📋 Instance Details:
  Instance ID: i-1234567890abcdef0
  Public IP: 3.66.231.25
  Key File: iris-ml-api-key.pem

⏳ Wait 2-3 minutes for initial setup to complete, then deploy your app!
```

### Step 2: Deploy v1 Model (Poor Baseline)

```bash
# Deploy v1 model to EC2
make deploy-v1-to-ec2
```

**This will:**
1. Train v1 model locally 
2. Copy project files to EC2
3. Train v1 model on EC2
4. Start API with v1 model
5. Test the deployment

**Expected output:**
```
🎯 Training v1 model locally...
📤 Copying project files to EC2...
🚀 Executing deployment on EC2...
✅ API health check passed
🎉 Deployment completed successfully!

🌐 Your ML API is now running at:
  Health Check: http://3.66.231.25:8000/health
  API Docs: http://3.66.231.25:8000/docs
  Model Info: http://3.66.231.25:8000/model-info
```

### Step 3: Test v1 Deployment

```bash
# Test the deployed v1 model
make test-ec2
```

**Expected v1 results:**
```json
{
  "active_model": "iris_v1.pkl",
  "version": "v1",
  "model_type": "DummyClassifier", 
  "accuracy": 0.333,
  "available_models": ["v1"]
}
```

### Step 4: Deploy v2 Model (CI/CD Improvement)

```bash
# Deploy improved v2 model (demonstrates CI/CD improvement)
make deploy-v2-to-ec2
```

**This demonstrates CI/CD improvement:**
1. Trains v2 model (RandomForestClassifier)
2. Updates model registry to activate v2
3. Performs zero-downtime deployment
4. Shows dramatic performance improvement

**Expected v2 results:**
```json
{
  "active_model": "iris_v2.pkl",
  "version": "v2", 
  "model_type": "RandomForestClassifier",
  "accuracy": 0.95,
  "available_models": ["v1", "v2"]
}
```

### Step 5: Compare Both Models on EC2

```bash
# Compare both model versions on EC2
PUBLIC_IP=$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3)

echo "=== Testing v1 (Poor Performance) ==="
curl "http://$PUBLIC_IP:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"

echo "=== Testing v2 (High Performance) ==="
curl "http://$PUBLIC_IP:8000/predict/v2?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
```

**Comparison Results:**
| Stage | Model | Accuracy | Algorithm | Purpose |
|-------|-------|----------|-----------|---------|
| **Baseline** | v1 | ~33% | DummyClassifier | Poor starting point |
| **CI/CD Improvement** | v2 | ~95% | RandomForestClassifier | Production ready |

### Step 6: Cleanup EC2 Resources

```bash
# Clean up EC2 resources when finished
make destroy-ec2
```

## 🛠️ All Available Commands

### Local Development
```bash
make v1     # Poor model (33%)
make v2     # Good model (90%)
make clean  # Clean up
```

### EC2 Deployment
```bash
make create-ec2        # Create EC2 instance
make deploy-v1-to-ec2  # Deploy v1 to EC2
make deploy-v2-to-ec2  # Deploy v2 to EC2
make test-ec2          # Test EC2 deployment
make destroy-ec2       # Clean up EC2 resources
```

### Testing Commands
```bash
# Health check
curl http://localhost:8000/health

# Model information
curl http://localhost:8000/model-info

# Prediction (uses active model)
curl "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"

# Force specific model version
curl "http://localhost:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
curl "http://localhost:8000/predict/v2?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
```

## 🎓 Complete CI/CD Demo Workflow

### Local Testing
```bash
# 1. Test v1 locally
make v1
curl http://localhost:8000/model-info

# 2. Test v2 locally
make v2
curl http://localhost:8000/model-info
```

### Cloud Deployment
```bash
# 3. Create EC2 instance
make create-ec2

# 4. Deploy v1 (poor baseline)
make deploy-v1-to-ec2

# 5. Test v1 on EC2
make test-ec2

# 6. Deploy v2 (CI/CD improvement)
make deploy-v2-to-ec2

# 7. Test v2 on EC2
make test-ec2

# 8. Compare both models
PUBLIC_IP=$(grep "Public IP:" ec2-instance-info.txt | cut -d' ' -f3)
curl "http://$PUBLIC_IP:8000/predict/v1?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
curl "http://$PUBLIC_IP:8000/predict/v2?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"

# 9. Cleanup when done
make destroy-ec2
```

## 🎯 Learning Outcomes

Students learn:
- **CI/CD Pipeline**: Model improvement workflow from 33% to 90% accuracy
- **Docker Deployment**: Containerized ML services
- **Cloud Infrastructure**: AWS EC2 deployment and management
- **API Testing**: REST endpoint consumption and validation
- **Performance Comparison**: Measuring real model improvement

**Perfect demonstration**: From poor baseline to production-ready model with complete local and cloud CI/CD workflow!

---

**🚀 Complete Docker + AWS ML CI/CD demonstration!**