# ML CI/CD Demo - Automated Model Deployment Pipeline

[![CI Pipeline](https://github.com/carloslme/itesm-cicd-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/carloslme/itesm-cicd-demo/actions/workflows/ci.yml)
[![CD Pipeline](https://github.com/carloslme/itesm-cicd-demo/actions/workflows/cd.yml/badge.svg)](https://github.com/carloslme/itesm-cicd-demo/actions/workflows/cd.yml)

A complete CI/CD pipeline for machine learning models using GitHub Actions and AWS EC2. This project demonstrates automated testing, building, and deployment of ML models with version control and infrastructure as code.

## Project Overview

This repository showcases a production-ready ML CI/CD pipeline that:
- ✅ **Trains and validates** multiple model versions
- ✅ **Automatically deploys** models to AWS EC2
- ✅ **Tests deployments** with comprehensive API validation
- ✅ **Manages infrastructure** with automated EC2 provisioning
- ✅ **Supports version switching** through simple configuration changes

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│  GitHub Actions │───▶│   AWS EC2       │
│                 │    │                 │    │                 │
│ • Model Code    │    │ • CI Pipeline   │    │ • FastAPI       │
│ • Training      │    │ • CD Pipeline   │    │ • ML Models     │
│ • API Code      │    │ • Testing       │    │ • Auto Scaling  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Model Versions

| Version | Algorithm | Accuracy | Use Case |
|---------|-----------|----------|----------|
| **v1** | Logistic Regression | ~33% | Baseline/Testing |
| **v2** | Random Forest | ~90% | Production |

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/carloslme/itesm-cicd-demo.git
cd itesm-cicd-demo
```

### 2. Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run v2 model (production)
make v2

# Run v1 model (baseline)
make v1

# Access API at http://localhost:8000
```

### 3. Deploy to AWS **Complete setup guide**: [AWS Deployment Guide](deploy-aws.md)

Quick deployment steps:
1. Set up AWS account and IAM user
2. Configure GitHub secrets (AWS credentials)
3. Change model version in `docker-compose.yml`
4. Push to main branch → automatic deployment! 🚀

## Project Structure

```
├── .github/workflows/     # CI/CD pipelines
│   ├── ci.yml            # Continuous Integration
│   └── cd.yml            # Continuous Deployment
├── src/
│   ├── api/              # FastAPI application
│   │   ├── main.py       # API endpoints
│   │   └── models/       # Trained model files
│   └── training/         # Model training scripts
│       └── train.py      # Training pipeline
├── docker/
│   └── api.Dockerfile    # Container configuration
├── deploy-aws.md         # 📋 AWS deployment guide
├── docker-compose.yml    # 🎯 Model version control
├── requirements.txt      # Python dependencies
└── Makefile             # Local development commands
```

## CI/CD Pipeline

### Continuous Integration (CI)
Triggered on every push and pull request:

```yaml
# .github/workflows/ci.yml
✅ Model Training Tests    # Train v1 and v2 models
✅ Docker Build Tests      # Build container images  
✅ API Integration Tests   # Test all endpoints
✅ Artifact Verification   # Validate model files
```

### Continuous Deployment (CD)
Triggered on main branch changes:

```yaml
# .github/workflows/cd.yml
✅ Model Version Detection # Auto-detect from docker-compose.yml
✅ EC2 Infrastructure      # Create/manage AWS resources
✅ Application Deployment  # Deploy and configure API
✅ Health Verification     # Test deployed endpoints
```

## Model Version Control

Control deployments by editing `docker-compose.yml`:

```yaml
services:
  ml-api:
    environment:
      - MODEL_VERSION=${MODEL_VERSION:-v2}  # 👈 Change this: v1 or v2
    labels:
      - "ml.auto-deploy=true"               # 👈 Enable auto-deployment
```

### Deployment Triggers

**Automatic Deployment:**
```bash
# Edit docker-compose.yml to change MODEL_VERSION
vim docker-compose.yml
git add docker-compose.yml
git commit -m "deploy: switch to v1 baseline model"  
git push origin main
# → Triggers automatic deployment to AWS! 🚀
```

**Manual Deployment:**
```bash
# GitHub Actions → CD Pipeline → Run workflow
# Select model version: v1 or v2
# Click: Run workflow
```

## API Endpoints

Once deployed, access your API at `http://YOUR-EC2-IP:8000`:

### Core Endpoints

| Endpoint | Method | Description | Example Response |
|----------|--------|-------------|------------------|
| `/health` | GET | System health check | `{"status": "healthy"}` |
| `/model-info` | GET | Model metadata | `{"version": "v2", "accuracy": 0.9}` |
| `/predict` | GET | Make predictions | `{"prediction": "setosa", "confidence": 0.95}` |
| `/docs` | GET | Interactive API docs | Swagger UI |

### Example Usage

```bash
# Health check
curl "http://YOUR-EC2-IP:8000/health"

# Get model information
curl "http://YOUR-EC2-IP:8000/model-info"

# Make a prediction
curl "http://YOUR-EC2-IP:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"

# Response
{
  "prediction": "setosa",
  "confidence": 0.95,
  "model_version": "v2",
  "features_used": {
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }
}
```

## Local Development

### Available Commands

```bash
# Local development
make v1              # Start v1 model locally
make v2              # Start v2 model locally  
make clean           # Clean up containers
make help            # Show all commands

# Model training
python src/training/train.py 1    # Train v1 model
python src/training/train.py 2    # Train v2 model

# API testing
curl http://localhost:8000/health
curl http://localhost:8000/model-info
```

### Development Workflow

1. **Make changes** to model or API code
2. **Test locally** with `make v2`
3. **Run tests** with CI pipeline
4. **Deploy** by changing `docker-compose.yml`
5. **Monitor** deployment in GitHub Actions

## AWS Infrastructure

### Automated Infrastructure Components

- **EC2 Instance**: t3.micro (Free Tier eligible)
- **Security Group**: SSH (22) + HTTP (8000) access
- **Key Pair**: Auto-generated SSH keys
- **AMI**: Latest Amazon Linux 2023 (auto-detected)

### Cost Information

**Free Tier Benefits** (12 months):
- EC2 t3.micro: 750 hours/month
- EBS Storage: 30 GB/month
- Data Transfer: 15 GB/month

**After Free Tier**: ~$10/month

## Monitoring and Observability

### Deployment Monitoring
- **GitHub Actions logs**: Detailed deployment progress
- **API health checks**: Automated endpoint testing
- **Model version verification**: Confirms correct deployment

### Troubleshooting
```bash
# Check deployment logs
GitHub → Actions → CD Pipeline → Latest run

# Connect to EC2 instance
ssh -i key.pem ec2-user@YOUR-IP

# Check API logs
tail -f /home/ec2-user/api.log

# Restart API if needed
pkill -f uvicorn
cd itesm-cicd-demo
MODEL_VERSION=v2 nohup python3 -m uvicorn src.api.main:app --host 0.0.0.0 --port 8000 > api.log 2>&1 &
```

## Security Features

### AWS Security
- ✅ **IAM roles** with minimal permissions
- ✅ **Security groups** with restricted access
- ✅ **Unique SSH keys** per deployment
- ✅ **Instance tagging** for tracking

### GitHub Security
- ✅ **Encrypted secrets** for AWS credentials
- ✅ **Production environment** protection
- ✅ **Branch protection** rules
- ✅ **Audit logs** for all deployments

## Documentation

- **[AWS Deployment Guide](deploy-aws.md)** - Complete setup instructions
- **[API Documentation](http://YOUR-EC2-IP:8000/docs)** - Interactive Swagger UI
- **[GitHub Actions](https://github.com/carloslme/itesm-cicd-demo/actions)** - CI/CD pipeline logs


## Prerequisites for AWS Deployment

Before deploying to AWS, ensure you have:

- ✅ **AWS Account** with valid payment method
- ✅ **IAM User** with EC2 permissions
- ✅ **GitHub Secrets** configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION)
- ✅ **Public Repository** (for EC2 to clone code)
- ✅ **Production Environment** set up in GitHub

**Complete setup guide**: [AWS Deployment Guide](deploy-aws.md)

## Performance Metrics

### Model Performance
- **v1 (Baseline)**: 33% accuracy - Logistic Regression
- **v2 (Production)**: 90% accuracy - Random Forest

### Deployment Performance
- **Build Time**: ~2-3 minutes
- **Deployment Time**: ~5-7 minutes  
- **API Response Time**: <100ms
- **Uptime**: 99.9% (AWS EC2 SLA)

## Use Cases

This pipeline is ideal for:
- **ML Model Experimentation** - Test different algorithms
- **Production ML Deployments** - Automated, reliable deployments  
- **Educational Projects** - Learn CI/CD best practices
- **Enterprise ML** - Scalable model deployment workflows

## Support

Need help? Here are your options:

1. **Check the [AWS Deployment Guide](deploy-aws.md)**
2. **Review [GitHub Actions logs](https://github.com/carloslme/itesm-cicd-demo/actions)**
3. **Open an [Issue](https://github.com/carloslme/itesm-cicd-demo/issues)**
4. **Start a [Discussion](https://github.com/carloslme/itesm-cicd-demo/discussions)**

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🎉 Ready to Deploy?

1. **Star this repo** if you find it helpful
2. **Follow the [AWS Deployment Guide](deploy-aws.md)**
3. **Deploy your first ML model** to AWS!

**Happy ML Engineering!** 🤖✨