# AWS Deployment Guide for ML CI/CD Pipeline

This guide explains how to deploy your machine learning models to AWS EC2 using the automated CI/CD pipeline.

## Prerequisites

### 1. AWS Account Setup

- **AWS Account**: Sign up at [aws.amazon.com](https://aws.amazon.com)
- **Payment Method**: Add a valid payment method (required even for Free Tier)
- **Region Selection**: Choose a region close to your users (e.g., `us-east-1`, `us-west-2`, `eu-west-1`)

### 2. IAM User Configuration

#### Create IAM User for GitHub Actions

1. **Access IAM Console**

   ```
   AWS Console → Services → IAM → Users → Create User
   ```

2. **User Details**
   - User name: `github-actions-ml-demo`
   - Access type: **Programmatic access** (Access keys only)

3. **Attach Permissions**

   Attach these AWS managed policies:
   - ✅ `AmazonEC2FullAccess`
   - ✅ `IAMReadOnlyAccess`

4. **Create Access Keys**
   - Go to **Security credentials** tab
   - Click **Create access key** → **Command Line Interface (CLI)**
   - **Save the credentials**:
     - Access Key ID (starts with `AKIA...`)
     - Secret Access Key (long string)

### 3. GitHub Repository Configuration

#### Set Repository Visibility

```bash
# Make repository public for EC2 to clone without authentication
GitHub Repo → Settings → General → Danger Zone → Change repository visibility → Make public
```

#### Configure GitHub Secrets

```bash
GitHub Repo → Settings → Secrets and variables → Actions → New repository secret
```

Add these **3 required secrets**:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | Your preferred AWS region | `us-east-1` |

#### Create Production Environment

```bash
GitHub Repo → Settings → Environments → New environment
```

- Environment name: `production`
- Optional: Add protection rules for manual approval

## Deployment Architecture

### Infrastructure Components

- **EC2 Instance**: t3.micro (Free Tier eligible)
- **Security Group**: Allows SSH (22) and HTTP (8000)
- **Key Pair**: Unique SSH key per deployment
- **AMI**: Latest Amazon Linux 2023 (auto-detected)

### Application Stack

- **OS**: Amazon Linux 2023
- **Runtime**: Python 3.9
- **Web Server**: Uvicorn (FastAPI)
- **Models**: Scikit-learn pickle files
- **API Framework**: FastAPI

## Deployment Methods

### Method 1: Automatic Deployment (Recommended)

Triggered automatically when you change the model version in `docker-compose.yml`:

1. **Edit Model Version**

   ```bash
   vim docker-compose.yml
   ```

   Change this line:

   ```yaml
   - MODEL_VERSION=${MODEL_VERSION:-v2}  # Change v2 to v1
   ```

2. **Commit and Push**

   ```bash
   git add docker-compose.yml
   git commit -m "deploy: switch to v1 baseline model"
   git push origin main
   ```

3. **Monitor Deployment**
   - Go to **GitHub Actions** tab
   - Watch the **CD Pipeline** workflow
   - Check logs for deployment status and public IP

### Method 2: Manual Deployment

Deploy specific model versions on-demand:

1. **Go to GitHub Actions**

   ```
   GitHub Repo → Actions → CD Pipeline → Run workflow
   ```

2. **Select Parameters**
   - Branch: `main`
   - Model version: `v1` or `v2`

3. **Click Run workflow**

## 📊 Model Versions

### v1 - Baseline Model

- **Algorithm**: Logistic Regression
- **Accuracy**: ~33% (intentionally poor)
- **Use case**: Baseline comparison
- **Features**: Basic feature set

### v2 - Production Model

- **Algorithm**: Random Forest
- **Accuracy**: ~90%
- **Use case**: Production deployment
- **Features**: Enhanced feature engineering

## 🔍 Deployment Process

The CD pipeline performs these steps automatically:

### 1. Model Version Detection

```bash
# Extracts version from docker-compose.yml
MODEL_VERSION=$(grep -E "MODEL_VERSION.*:-.*" docker-compose.yml | ...)
```

### 2. EC2 Instance Management

- **Check existing instance**: Reuses if already running
- **Create new instance**: If none exists or terminated
- **Dynamic AMI selection**: Finds latest Amazon Linux for your region

### 3. Security Configuration

- **Key pair generation**: Unique SSH key per deployment
- **Security group setup**: Ports 22 (SSH) and 8000 (HTTP)
- **Instance tagging**: For identification and cost tracking

### 4. Application Deployment

- **Source code transfer**: Clones public repository
- **Dependency installation**: pip install requirements
- **Model training**: Trains selected model version
- **API startup**: Starts FastAPI server on port 8000

### 5. Deployment Testing

- **Health check**: `GET /health`
- **Model info**: `GET /model-info`
- **Prediction test**: `GET /predict?...`
- **Version verification**: Confirms correct model deployed

## 🌐 API Endpoints

Once deployed, your API will be available at `http://YOUR-EC2-IP:8000`:

### Core Endpoints

| Endpoint | Method | Description | Example |
|----------|--------|-------------|---------|
| `/health` | GET | Health check | `{"status": "healthy"}` |
| `/model-info` | GET | Model metadata | `{"version": "v2", "accuracy": 0.9}` |
| `/predict` | GET | Make prediction | See below |
| `/docs` | GET | Interactive API docs | Swagger UI |

### Prediction Examples

```bash
# Basic prediction
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

## Cost Information

### AWS Free Tier Benefits

- **EC2 t3.micro**: 750 hours/month for 12 months
- **EBS Storage**: 30 GB/month for 12 months
- **Data Transfer**: 15 GB/month outbound

### Expected Monthly Costs (After Free Tier)

- **EC2 t3.micro**: ~$8.50/month
- **EBS 8GB gp3**: ~$0.80/month
- **Data Transfer**: Usually <$1/month for testing
- **Total**: ~$10/month

### Cost Optimization Tips

```bash
# Terminate instances when not needed
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0

# Set up billing alerts
AWS Console → Billing → Budgets → Create budget

# Use AWS Cost Explorer
AWS Console → Cost Management → Cost Explorer
```

## Monitoring and Troubleshooting

### Finding Your Deployment

After successful deployment, check the GitHub Actions logs for:

```bash
🧪 Testing deployment at XX.XX.XX.XX:8000
✅ API is ready!
Health response: {"status":"healthy"}
Model info: {"model":"iris_classifier","version":"v2",...}
✅ All deployment tests passed!
```

### Common Issues and Solutions

#### 1. AWS Credentials Error

```bash
Error: AWS credentials not configured
```

**Solution**: Verify all 3 GitHub secrets are set correctly

#### 2. EC2 Instance Creation Failed

```bash
Error: InvalidAMIID.NotFound
```

**Solution**: Pipeline auto-detects correct AMI. If persistent, try different region.

#### 3. SSH Connection Timeout

```bash
Error: SSH connection failed
```

**Solution**: Wait longer for instance initialization (up to 5 minutes)

#### 4. API Not Responding

```bash
Error: API health check failed
```

**Solution**: Check EC2 instance logs via SSH:

```bash
# SSH into instance (key provided in GitHub Actions logs)
ssh -i key.pem ec2-user@YOUR-IP
tail -f /home/ec2-user/api.log
```

### Manual Instance Management

#### Connect to EC2 Instance

```bash
# Get connection details from GitHub Actions logs
ssh -i ml-demo-key-TIMESTAMP.pem ec2-user@YOUR-PUBLIC-IP
```

#### Check API Status

```bash
# On EC2 instance
ps aux | grep uvicorn
tail -f /home/ec2-user/api.log
curl localhost:8000/health
```

#### Restart API

```bash
# On EC2 instance
pkill -f uvicorn
cd itesm-cicd-demo
MODEL_VERSION=v2 nohup python3 -m uvicorn src.api.main:app --host 0.0.0.0 --port 8000 > /home/ec2-user/api.log 2>&1 &
```

## Security Best Practices

### AWS Security

- Use IAM user with minimal required permissions
- Rotate access keys every 90 days
- Enable CloudTrail for API logging
- Set up billing alerts

### EC2 Security

- Unique SSH key pairs per deployment
- Security groups with minimal port access
- Regular OS updates via user-data script
- Instance termination when not needed

### GitHub Security

- Use repository secrets for sensitive data
- Enable branch protection rules
- Use production environments with approvals
- Regular secret rotation

## Additional Resources

### AWS Documentation

- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Free Tier](https://aws.amazon.com/free/)

### GitHub Actions

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS Actions](https://github.com/aws-actions)

### FastAPI

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Uvicorn Deployment](https://www.uvicorn.org/deployment/)

## Next Steps

1. **Complete Prerequisites**: Set up AWS account and GitHub secrets
2. **Test Deployment**: Try manual deployment first
3. **Set Up Monitoring**: Configure AWS CloudWatch and billing alerts
4. **Implement Scaling**: Consider Auto Scaling Groups for production
5. **Add HTTPS**: Use Application Load Balancer with SSL certificate
6. **Database Integration**: Add RDS for model metadata storage

## Support

If you encounter issues:

1. **Check GitHub Actions logs** for detailed error messages
2. **Verify prerequisites** are completed correctly
3. **Review AWS CloudTrail** for API call logs
4. **Check EC2 instance logs** via SSH connection
5. **Create GitHub issue** with error details for help

---

**Happy Deploying!** Your ML models are now automatically deployed to AWS with every code change!
