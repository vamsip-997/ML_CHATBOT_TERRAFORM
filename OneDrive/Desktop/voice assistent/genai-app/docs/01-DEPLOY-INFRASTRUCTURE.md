# Deploy Infrastructure with Terraform

This guide walks you through deploying the complete AWS infrastructure for the GenAI Chatbot.

## Prerequisites

### 1. Install Required Tools

```bash
# Terraform (version 1.0+)
# macOS
brew install terraform

# Windows (using Chocolatey)
choco install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform --version
```

```bash
# AWS CLI
# macOS
brew install awscli

# Windows
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

### 2. Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Enter your credentials:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1
# Default output format: json

# Verify credentials
aws sts get-caller-identity
```

### 3. Create ECR Repository

Before deploying, create an ECR repository for your Docker images:

```bash
# Create ECR repository
aws ecr create-repository \
  --repository-name genai-chatbot \
  --region us-east-1 \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256

# Get repository URI (save this for later)
aws ecr describe-repositories \
  --repository-names genai-chatbot \
  --query 'repositories[0].repositoryUri' \
  --output text
```

### 4. Create S3 Backend for Terraform State (Recommended)

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Deployment Steps

### Step 1: Configure Terraform Backend

Edit `terraform/main.tf` to configure the S3 backend:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "genai-chatbot/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

### Step 2: Configure Variables

```bash
cd genai-app/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# Project Configuration
project_name = "genai-chatbot"
environment  = "dev"

# AWS Configuration
aws_region = "us-east-1"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# ECS Configuration
ecs_task_cpu       = "512"   # 0.5 vCPU
ecs_task_memory    = "1024"  # 1 GB
ecs_desired_count  = 2       # Number of tasks
ecs_min_capacity   = 1
ecs_max_capacity   = 4

# ECR Repository (replace with your ECR URL)
ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/genai-chatbot"
app_version        = "latest"

# CORS Configuration
cors_origins = ["*"]  # Update with your domain in production
```

### Step 3: Initialize Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Expected output:
# Terraform has been successfully initialized!
```

### Step 4: Validate Configuration

```bash
# Format Terraform files
terraform fmt

# Validate configuration
terraform validate

# Expected output:
# Success! The configuration is valid.
```

### Step 5: Plan Deployment

```bash
# Create execution plan
terraform plan -out=tfplan

# Review the plan carefully
# It will show all resources to be created:
# - VPC and networking (subnets, IGW, NAT)
# - Security groups
# - Load balancer
# - ECS cluster and service
# - S3 buckets
# - OpenSearch Serverless
# - Bedrock Knowledge Base
# - IAM roles and policies
```

### Step 6: Deploy Infrastructure

```bash
# Apply the plan
terraform apply tfplan

# Or apply directly (will prompt for confirmation)
terraform apply

# This will take 10-15 minutes to complete
```

### Step 7: Capture Outputs

```bash
# Get important outputs
terraform output

# Save these values:
# - alb_dns_name: Load balancer URL
# - knowledge_base_id: Bedrock KB ID
# - documents_bucket_name: S3 bucket for uploads
# - kb_source_bucket_name: S3 bucket for KB documents

# Get specific output
terraform output -raw alb_dns_name
terraform output -raw knowledge_base_id
```

## Post-Deployment Configuration

### 1. Build and Push Docker Image

```bash
# Navigate to project root
cd ..

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# Build image
docker build -t genai-chatbot .

# Tag image
docker tag genai-chatbot:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/genai-chatbot:latest

# Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/genai-chatbot:latest
```

### 2. Update ECS Service

```bash
# Force new deployment to pull the latest image
aws ecs update-service \
  --cluster genai-chatbot-cluster-dev \
  --service genai-chatbot-service-dev \
  --force-new-deployment \
  --region us-east-1

# Monitor deployment
aws ecs describe-services \
  --cluster genai-chatbot-cluster-dev \
  --services genai-chatbot-service-dev \
  --region us-east-1
```

### 3. Upload Documents to Knowledge Base

```bash
# Get KB source bucket name
KB_BUCKET=$(terraform output -raw kb_source_bucket_name)

# Upload your documents
aws s3 cp ./documents/ s3://$KB_BUCKET/documents/ --recursive

# Sync Knowledge Base
KB_ID=$(terraform output -raw knowledge_base_id)
DATA_SOURCE_ID=$(aws bedrock-agent list-data-sources \
  --knowledge-base-id $KB_ID \
  --query 'dataSourceSummaries[0].dataSourceId' \
  --output text)

aws bedrock-agent start-ingestion-job \
  --knowledge-base-id $KB_ID \
  --data-source-id $DATA_SOURCE_ID

# Monitor ingestion
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id $KB_ID \
  --data-source-id $DATA_SOURCE_ID
```

### 4. Test the Deployment

```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Health check
curl http://$ALB_DNS/health

# Test chat endpoint
curl -X POST http://$ALB_DNS/api/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What information do you have?",
    "use_kb": true
  }'
```

## Infrastructure Overview

### Created Resources

**Networking:**
- 1 VPC with DNS support
- 2 Public subnets (for ALB)
- 2 Private subnets (for ECS tasks)
- 1 Internet Gateway
- 2 NAT Gateways (for outbound internet)
- Route tables and associations

**Compute:**
- 1 ECS Cluster (Fargate)
- 1 ECS Service (2 tasks by default)
- 1 Application Load Balancer
- 1 Target Group
- Auto-scaling configuration

**Storage:**
- 2 S3 buckets (documents + KB source)
- Versioning enabled
- Encryption at rest
- Lifecycle policies

**AI/ML:**
- 1 OpenSearch Serverless collection
- 1 Bedrock Knowledge Base
- 1 Data Source (S3)
- Vector embeddings configuration

**Security:**
- 5 IAM roles (ECS execution, task, Bedrock KB)
- Security groups (ALB, ECS tasks)
- Encryption policies
- Access policies

**Monitoring:**
- CloudWatch Log Groups
- ECS Container Insights
- ALB access logs

## Cost Estimation

**Monthly costs (us-east-1, approximate):**

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| ECS Fargate | 2 tasks (0.5 vCPU, 1GB) | ~$30 |
| NAT Gateway | 2 NAT Gateways | ~$65 |
| Application Load Balancer | 1 ALB | ~$20 |
| OpenSearch Serverless | Vector search | ~$90 |
| S3 Storage | 10GB | ~$0.25 |
| Bedrock API Calls | 10k requests | ~$30 |
| Data Transfer | Minimal | ~$5 |
| **Total** | | **~$240/month** |

**Cost Optimization Tips:**
- Use 1 NAT Gateway for dev environments
- Reduce ECS task count during off-hours
- Use S3 lifecycle policies
- Monitor Bedrock usage
- Consider Savings Plans for production

## Troubleshooting

### Terraform Errors

**Error: "Error creating ECS Service"**
```bash
# Check if ECR image exists
aws ecr describe-images \
  --repository-name genai-chatbot \
  --region us-east-1

# If no images, build and push first
```

**Error: "Resource already exists"**
```bash
# Import existing resources
terraform import aws_s3_bucket.genai_documents bucket-name

# Or destroy and recreate
terraform destroy -target=aws_s3_bucket.genai_documents
terraform apply
```

### Service Not Starting

```bash
# Check ECS task logs
aws logs tail /ecs/genai-chatbot-dev --follow

# Check task stopped reason
aws ecs describe-tasks \
  --cluster genai-chatbot-cluster-dev \
  --tasks TASK_ID \
  --query 'tasks[0].stoppedReason'
```

### Knowledge Base Issues

```bash
# Check KB status
aws bedrock-agent get-knowledge-base --knowledge-base-id $KB_ID

# Check data source sync status
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id $KB_ID \
  --data-source-id $DATA_SOURCE_ID
```

## Cleanup

To destroy all infrastructure:

```bash
cd terraform

# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm by typing: yes
```

**Important:** This will delete all resources including S3 buckets. Make sure to backup any important data first.

## Next Steps

1. ✅ Infrastructure deployed
2. 📝 [Test the application locally](./02-TEST-LOCALLY.md)
3. ⚙️ [Customize configuration](./03-CUSTOMIZE-CONFIG.md)
4. 🚀 [Set up CI/CD pipeline](./04-SETUP-GITHUB-ACTIONS.md)
5. 🎯 [Add advanced features](./05-ADD-FEATURES.md)

## Support

For issues or questions:
- Check CloudWatch Logs
- Review AWS Service Health Dashboard
- Consult AWS Bedrock documentation
- Review Terraform state: `terraform show`
