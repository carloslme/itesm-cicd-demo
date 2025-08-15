#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Creating EC2 instance for ML API deployment"

# Configuration
INSTANCE_NAME="iris-ml-api"
KEY_NAME="iris-ml-api-key"
SECURITY_GROUP_NAME="iris-ml-api-sg"
INSTANCE_TYPE="t3.micro"
REGION="us-east-1"

echo "✅ Using instance type: $INSTANCE_TYPE"

# Get latest Amazon Linux 2 AMI ID
echo "🔍 Getting latest Amazon Linux 2 AMI..."
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
              "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

echo "Using AMI ID: $AMI_ID"

# Create security group if it doesn't exist
echo "🔒 Creating security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for Iris ML API" \
    --query 'GroupId' \
    --output text 2>/dev/null) || {
    echo "Security group already exists, getting ID..."
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
        --group-names $SECURITY_GROUP_NAME \
        --query 'SecurityGroups[0].GroupId' \
        --output text)
}

echo "Security Group ID: $SECURITY_GROUP_ID"

# Add security group rules (ignore errors if they already exist)
echo "🔓 Configuring security group rules..."
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 2>/dev/null || echo "SSH rule already exists"

aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 8000 \
    --cidr 0.0.0.0/0 2>/dev/null || echo "Port 8000 rule already exists"

aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 2>/dev/null || echo "HTTP rule already exists"

# Create key pair - check AWS first, not just local file
echo "🔑 Managing key pair..."
if aws ec2 describe-key-pairs --key-names $KEY_NAME &>/dev/null; then
    echo "Key pair exists in AWS: $KEY_NAME"
    # Check if local file exists
    if [ ! -f "${KEY_NAME}.pem" ]; then
        echo "❌ Local key file missing. Please download from AWS Console."
        echo "📝 Go to EC2 → Key Pairs → $KEY_NAME → Actions → Download"
        echo "💡 Or delete the key pair in AWS and run this script again to create a new one."
        exit 1
    fi
    echo "✅ Local key file found: ${KEY_NAME}.pem"
else
    echo "Creating new key pair in AWS..."
    # Remove local file if it exists but key doesn't exist in AWS
    rm -f ${KEY_NAME}.pem
    
    # Try to create key pair with error handling
    if ! aws ec2 create-key-pair \
        --key-name $KEY_NAME \
        --query 'KeyMaterial' \
        --output text > ${KEY_NAME}.pem 2>/dev/null; then
        
        echo "❌ Failed to create key pair. Checking IAM permissions..."
        echo "📝 Required permissions:"
        echo "  - ec2:CreateKeyPair"
        echo "  - ec2:DescribeKeyPairs"
        echo ""
        echo "🔧 Please add these permissions to your IAM user or create key pair manually:"
        echo "  1. Go to AWS Console → EC2 → Key Pairs"
        echo "  2. Create key pair named: $KEY_NAME"
        echo "  3. Download the .pem file to this directory"
        echo "  4. Run this script again"
        exit 1
    fi
    
    chmod 400 ${KEY_NAME}.pem
    echo "Key pair created: ${KEY_NAME}.pem"
fi

# Ensure key file has correct permissions
chmod 400 ${KEY_NAME}.pem

# Create user data script for initial setup
cat > user-data.sh << 'EOF'
#!/bin/bash
yum update -y
yum install -y docker git python3 python3-pip curl

# Start Docker
service docker start
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /home/ec2-user/app
chown ec2-user:ec2-user /home/ec2-user/app

# Create a simple status file
echo "EC2 setup completed at $(date)" > /home/ec2-user/setup-complete.txt
chown ec2-user:ec2-user /home/ec2-user/setup-complete.txt
EOF

# Launch EC2 instance
echo "🚀 Launching EC2 instance..."
echo "  Instance Type: $INSTANCE_TYPE"
echo "  AMI ID: $AMI_ID"
echo "  Key Name: $KEY_NAME"
echo "  Security Group: $SECURITY_GROUP_ID"

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --user-data file://user-data.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance ID: $INSTANCE_ID"

# Wait for instance to be running
echo "⏳ Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "✅ EC2 instance created successfully!"
echo "📋 Instance Details:"
echo "  Instance ID: $INSTANCE_ID"
echo "  Instance Type: $INSTANCE_TYPE"
echo "  Public IP: $PUBLIC_IP"
echo "  Key File: ${KEY_NAME}.pem"
echo ""
echo "🔗 Connect to your instance:"
echo "  ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP"
echo ""
echo "⏳ Wait 2-3 minutes for initial setup to complete, then deploy your app!"

# Save instance info to file
cat > ec2-instance-info.txt << EOF
Instance ID: $INSTANCE_ID
Instance Type: $INSTANCE_TYPE
Public IP: $PUBLIC_IP
Key File: ${KEY_NAME}.pem
Security Group: $SECURITY_GROUP_ID

Connect command:
ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP

API URL (after deployment):
http://$PUBLIC_IP:8000
EOF

echo "📄 Instance info saved to: ec2-instance-info.txt"

# Cleanup
rm -f user-data.sh