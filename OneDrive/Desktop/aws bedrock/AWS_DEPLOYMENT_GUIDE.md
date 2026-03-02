# AWS Production Deployment Guide

## 🚀 Complete Production Deployment for AI Assistant

This guide will help you deploy the AI Assistant to AWS with production-grade infrastructure, monitoring, and security.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Pre-Deployment Setup](#pre-deployment-setup)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Configuration](#post-deployment-configuration)
6. [Testing](#testing)
7. [Monitoring & Logging](#monitoring--logging)
8. [Cost Optimization](#cost-optimization)
9. [Security Best Practices](#security-best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools
- ✅ AWS CLI (v2.x or higher)
- ✅ Python 3.11 or higher
- ✅ pip (Python package manager)
- ✅ PowerShell 7+ (Windows) or Bash (Linux/Mac)

### AWS Account Setup
1. **AWS Account** with appropriate permissions
2. **IAM User** with following permissions:
   - CloudFormation (Full Access)
   - Lambda (Full Access)
   - API Gateway (Full Access)
   - S3 (Full Access)
   - IAM (Create/Attach Roles)
   - CloudWatch (Full Access)

3. **Amazon Bedrock Access**
   - Bedrock service enabled in your region
   - Claude 3 Haiku model access granted
   - Use case details submitted (if required)

### Cost Estimate
- **Lambda**: ~$0.20 per 1M requests + compute time
- **API Gateway**: ~$3.50 per 1M requests
- **S3**: ~$0.023 per GB stored
- **CloudWatch Logs**: ~$0.50 per GB ingested
- **Bedrock**: Pay-per-use (varies by model)

**Estimated Monthly Cost (1000 requests/day)**: ~$10-30

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌────────────────┐      ┌─────────────────┐                   │
│  │  API Gateway   │─────▶│  Lambda         │                   │
│  │  (REST API)    │      │  (AI Assistant) │                   │
│  └────────────────┘      └─────────────────┘                   │
│         │                         │                              │
│         │                         ▼                              │
│         │                 ┌─────────────────┐                   │
│         │                 │  Amazon Bedrock │                   │
│         │                 │  (Claude 3)     │                   │
│         │                 └─────────────────┘                   │
│         │                         │                              │
│         │                         ▼                              │
│         │                 ┌─────────────────┐                   │
│         │                 │      S3         │                   │
│         │                 │  (Storage)      │                   │
│         │                 └─────────────────┘                   │
│         │                                                        │
│         ▼                                                        │
│  ┌────────────────────────────────────────┐                    │
│  │         CloudWatch                      │                    │
│  │  (Logs, Metrics, Alarms, Dashboard)    │                    │
│  └────────────────────────────────────────┘                    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Components

1. **API Gateway**: RESTful API endpoint with CORS support
2. **Lambda Function**: Serverless compute running the AI Assistant
3. **Amazon Bedrock**: AI model service (Claude 3 Haiku)
4. **S3 Bucket**: Storage for AI responses (optional)
5. **CloudWatch**: Logging, monitoring, and alarms
6. **IAM Roles**: Secure access management

---

## Pre-Deployment Setup

### 1. Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json)
```

### 2. Enable Amazon Bedrock

1. Navigate to Amazon Bedrock console
2. Go to "Model access" in the left menu
3. Click "Request model access"
4. Select **Anthropic Claude 3 Haiku**
5. Submit use case details if prompted
6. Wait for approval (usually instant, sometimes up to 15 minutes)

### 3. Verify Bedrock Access

```bash
# Test Bedrock access
aws bedrock list-foundation-models --region us-east-1 --query 'modelSummaries[?contains(modelId, `claude-3-haiku`)].modelId'
```

You should see: `anthropic.claude-3-haiku-20240307-v1:0`

### 4. Set Environment Variables (Optional)

```bash
# Linux/Mac
export AWS_REGION=us-east-1
export ENVIRONMENT=production

# Windows PowerShell
$env:AWS_REGION="us-east-1"
$env:ENVIRONMENT="production"
```

---

## Deployment Steps

### Option 1: Automated Deployment (Recommended)

#### For Windows (PowerShell):

```powershell
# Run deployment script
.\deploy.ps1
```

#### For Linux/Mac (Bash):

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

The script will:
1. ✅ Check prerequisites
2. ✅ Create Lambda deployment package
3. ✅ Deploy CloudFormation stack
4. ✅ Update Lambda function code
5. ✅ Display deployment information
6. ✅ Offer to test the deployment

### Option 2: Manual Deployment

#### Step 1: Create Deployment Package

```bash
# Create package directory
mkdir lambda_package
cd lambda_package

# Copy Lambda function
cp ../lambda_function.py .

# Install dependencies
pip install -r ../requirements_lambda.txt -t .

# Create zip file
zip -r ../lambda_deployment.zip .
cd ..

# Clean up
rm -rf lambda_package
```

#### Step 2: Deploy CloudFormation Stack

```bash
aws cloudformation create-stack \
  --stack-name ai-assistant-stack \
  --template-body file://cloudformation-template.yaml \
  --parameters \
      ParameterKey=ProjectName,ParameterValue=ai-assistant \
      ParameterKey=BedrockRegion,ParameterValue=us-east-1 \
      ParameterKey=Environment,ParameterValue=production \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name ai-assistant-stack \
  --region us-east-1
```

#### Step 3: Update Lambda Code

```bash
# Get function name
FUNCTION_NAME=$(aws cloudformation describe-stacks \
  --stack-name ai-assistant-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionName`].OutputValue' \
  --output text)

# Update function code
aws lambda update-function-code \
  --function-name $FUNCTION_NAME \
  --zip-file fileb://lambda_deployment.zip \
  --region us-east-1
```

#### Step 4: Get API Endpoint

```bash
aws cloudformation describe-stacks \
  --stack-name ai-assistant-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' \
  --output text
```

---

## Post-Deployment Configuration

### 1. Test the Deployment

#### Quick Test (curl):

```bash
# Get API endpoint from deployment-info.txt
API_ENDPOINT="<your-api-endpoint>"

# Test general question
curl -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "What is Python?",
    "response_type": "general"
  }'
```

#### Comprehensive Test:

```bash
# Linux/Mac
chmod +x test-api.sh
./test-api.sh

# Windows
.\test-api.ps1
```

### 2. Set Up CloudWatch Dashboard

```bash
# Create dashboard
aws cloudwatch put-dashboard \
  --dashboard-name ai-assistant-dashboard \
  --dashboard-body file://monitoring-dashboard.json
```

Access at: AWS Console → CloudWatch → Dashboards → ai-assistant-dashboard

### 3. Configure Alarms

The CloudFormation stack automatically creates:
- **Error Alarm**: Triggers when errors > 5 in 5 minutes
- **Throttle Alarm**: Triggers when throttles > 3 in 5 minutes

To add SNS notifications:

```bash
# Create SNS topic
aws sns create-topic --name ai-assistant-alerts

# Subscribe your email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:ai-assistant-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com

# Update alarms to use SNS topic
# (Update CloudFormation template with AlarmActions)
```

### 4. Set Up Custom Domain (Optional)

1. **Get a domain** from Route 53 or external registrar
2. **Create ACM certificate** for your domain
3. **Create API Gateway custom domain**:

```bash
aws apigateway create-domain-name \
  --domain-name api.yourdomain.com \
  --certificate-arn arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID
```

4. **Map to API Gateway stage**
5. **Update Route 53** with API Gateway domain

---

## Testing

### Manual Testing

```bash
# Test all response types
./test-api.sh  # Linux/Mac
.\test-api.ps1 # Windows
```

### Load Testing

```bash
# Using Apache Bench (install first)
ab -n 100 -c 10 -p test-payload.json -T application/json \
  https://your-api-endpoint/generate
```

### Integration Testing

Create `test-payload.json`:

```json
{
  "user_input": "What is machine learning?",
  "response_type": "explain",
  "output_format": "markdown"
}
```

---

## Monitoring & Logging

### CloudWatch Logs

View logs:
```bash
# Stream logs in real-time
aws logs tail /aws/lambda/ai-assistant-function --follow

# Query logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/ai-assistant-function \
  --filter-pattern "ERROR"
```

### Key Metrics to Monitor

1. **Invocations**: Total requests
2. **Duration**: Response time
3. **Errors**: Failed requests
4. **Throttles**: Rate limit hits
5. **Concurrent Executions**: Parallel requests
6. **API Gateway 4XX/5XX**: Client/Server errors

### Setting Up Alerts

```bash
# Create SNS topic for alerts
aws sns create-topic --name ai-assistant-critical-alerts

# Subscribe
aws sns subscribe \
  --topic-arn arn:aws:sns:REGION:ACCOUNT_ID:ai-assistant-critical-alerts \
  --protocol email \
  --notification-endpoint admin@company.com
```

---

## Cost Optimization

### 1. Lambda Optimization
- Use **512 MB memory** (optimal for this workload)
- Set **300s timeout** (adjust based on needs)
- Enable **Reserved Concurrency** if needed

### 2. API Gateway Optimization
- Enable **caching** for repeated queries
- Use **usage plans** to control costs
- Implement **API keys** for tracking

### 3. S3 Optimization
- Enable **lifecycle policies** (auto-delete old responses)
- Use **Intelligent-Tiering** storage class
- Enable **compression** for responses

### 4. Bedrock Optimization
- Use **Claude Haiku** (most cost-effective)
- Limit **max_tokens** to reasonable values
- Cache common responses

---

## Security Best Practices

### 1. API Security

```bash
# Add API Key requirement
aws apigateway create-api-key \
  --name ai-assistant-api-key \
  --enabled

# Create usage plan
aws apigateway create-usage-plan \
  --name ai-assistant-plan \
  --throttle rateLimit=100,burstLimit=200
```

### 2. Lambda Security
- ✅ Least privilege IAM role
- ✅ Environment variable encryption
- ✅ VPC deployment (if needed)
- ✅ Enable AWS X-Ray tracing

### 3. Data Security
- ✅ S3 bucket encryption (AES-256)
- ✅ Block public access
- ✅ Enable versioning
- ✅ Enable access logging

### 4. Network Security
- Enable **WAF** on API Gateway
- Add **rate limiting**
- Implement **IP whitelisting** (if applicable)
- Enable **CORS** properly

---

## Troubleshooting

### Common Issues

#### 1. Bedrock Access Denied

**Error**: `ResourceNotFoundException` or `AccessDeniedException`

**Solution**:
```bash
# Check model access
aws bedrock list-foundation-models --region us-east-1

# Request access in Bedrock console
# Model access → Request model access → Select Claude 3 Haiku
```

#### 2. Lambda Timeout

**Error**: Task timed out after X seconds

**Solution**:
- Increase timeout in CloudFormation template
- Optimize prompt length
- Reduce max_tokens

#### 3. API Gateway 403 Error

**Error**: `{"message":"Missing Authentication Token"}`

**Solution**:
- Verify endpoint URL is correct
- Check method is POST, not GET
- Verify API is deployed to correct stage

#### 4. S3 Permission Denied

**Error**: `Access Denied` when saving to S3

**Solution**:
```bash
# Verify bucket policy
aws s3api get-bucket-policy --bucket ai-assistant-responses-ACCOUNT_ID

# Check Lambda role has s3:PutObject permission
```

### Debug Mode

Enable debugging in Lambda:

```bash
aws lambda update-function-configuration \
  --function-name ai-assistant-function \
  --environment Variables={DEBUG=true}
```

### View Logs

```bash
# Real-time logs
aws logs tail /aws/lambda/ai-assistant-function --follow --format short

# Recent errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/ai-assistant-function \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000
```

---

## Updating the Deployment

### Update Lambda Code

```bash
# Recreate deployment package
./deploy.ps1  # or ./deploy.sh

# Or manually:
zip -r lambda_deployment.zip lambda_function.py
aws lambda update-function-code \
  --function-name ai-assistant-function \
  --zip-file fileb://lambda_deployment.zip
```

### Update Infrastructure

```bash
# Update CloudFormation stack
aws cloudformation update-stack \
  --stack-name ai-assistant-stack \
  --template-body file://cloudformation-template.yaml \
  --parameters <same-as-before> \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## Rollback

### Rollback CloudFormation Stack

```bash
aws cloudformation cancel-update-stack \
  --stack-name ai-assistant-stack

# Or rollback to previous version
aws cloudformation continue-update-rollback \
  --stack-name ai-assistant-stack
```

### Rollback Lambda Version

```bash
# List versions
aws lambda list-versions-by-function \
  --function-name ai-assistant-function

# Publish specific version as $LATEST
aws lambda update-alias \
  --function-name ai-assistant-function \
  --name PROD \
  --function-version <version-number>
```

---

## Cleanup (Delete Everything)

```bash
# Delete CloudFormation stack (deletes all resources)
aws cloudformation delete-stack \
  --stack-name ai-assistant-stack

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name ai-assistant-stack

# Manually delete S3 bucket if not empty
aws s3 rm s3://ai-assistant-responses-ACCOUNT_ID --recursive
aws s3 rb s3://ai-assistant-responses-ACCOUNT_ID
```

---

## Next Steps

1. ✅ **Deploy to production** following this guide
2. ✅ **Set up monitoring** with CloudWatch Dashboard
3. ✅ **Configure alerts** with SNS
4. ✅ **Test thoroughly** with test scripts
5. ✅ **Document** your specific configuration
6. ✅ **Train team** on monitoring and troubleshooting
7. ✅ **Plan for scaling** (increase limits if needed)

---

## Support & Resources

- **AWS Documentation**: https://docs.aws.amazon.com/
- **Bedrock Pricing**: https://aws.amazon.com/bedrock/pricing/
- **Lambda Limits**: https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html
- **API Gateway Limits**: https://docs.aws.amazon.com/apigateway/latest/developerguide/limits.html

---

## Summary

Your AI Assistant is now deployed with:

✅ **Production-grade infrastructure** (CloudFormation)  
✅ **Serverless architecture** (Lambda + API Gateway)  
✅ **AI capabilities** (Amazon Bedrock Claude 3)  
✅ **Storage** (S3 with encryption)  
✅ **Monitoring** (CloudWatch logs, metrics, alarms)  
✅ **Security** (IAM roles, encryption, CORS)  
✅ **Scalability** (Auto-scaling Lambda)  
✅ **Cost optimization** (Pay-per-use pricing)  

**Your AI Assistant is production-ready! 🚀**
