# 🚀 Complete Setup Guide - AI Blog Generator

**One-stop guide with all commands and steps to get your blog generator running!**

---

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [AWS Configuration](#aws-configuration)
4. [Enable Amazon Bedrock](#enable-amazon-bedrock)
5. [Testing Options](#testing-options)
6. [AWS Lambda Deployment](#aws-lambda-deployment)
7. [Troubleshooting](#troubleshooting)

---

## 1️⃣ Prerequisites

### What You Need
- ✅ Python 3.9 or higher
- ✅ AWS Account
- ✅ Internet connection
- ✅ Text editor (VS Code, Notepad++, etc.)

### Check Python Version
```bash
python --version
```
Should show: `Python 3.9.x` or higher

---

## 2️⃣ Initial Setup

### Step 1: Navigate to Project Directory
```bash
# Windows (PowerShell)
cd "C:\Users\DELL\OneDrive\Desktop\aws bedrock"

# Or create a new directory
mkdir blog-generator
cd blog-generator
```

### Step 2: Install Dependencies
```bash
pip install -r requirements.txt
```

**Expected output:**
```
Successfully installed boto3-1.34.x botocore-1.34.x flask-3.1.x
```

### Step 3: Verify Installation
```bash
# Check if packages are installed
pip list | findstr "boto3 flask"
```

---

## 3️⃣ AWS Configuration

### Step 1: Get AWS Access Keys

#### Option A: From AWS Console
1. **Go to:** https://console.aws.amazon.com/iam/
2. **Click:** Users → Your username
3. **Click:** Security credentials tab
4. **Scroll to:** Access keys section
5. **Click:** Create access key
6. **Select:** Command Line Interface (CLI)
7. **Check:** Confirmation box
8. **Click:** Next → Create access key
9. **IMPORTANT:** Copy both:
   - Access Key ID (e.g., `AKIAIOSFODNN7EXAMPLE`)
   - Secret Access Key (click "Show" to reveal)
10. **Click:** Download .csv file (backup)

### Step 2: Configure AWS CLI
```bash
aws configure
```

**Enter when prompted:**
```
AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
Default region name [None]: us-east-1
Default output format [None]: json
```

### Step 3: Verify AWS Configuration
```bash
# Check current AWS identity
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDAI...",
    "Account": "335660922845",
    "Arn": "arn:aws:iam::335660922845:user/Rishi"
}
```

### Step 4: Create S3 Bucket (if not exists)
```bash
# Check if bucket exists
aws s3 ls s3://blog-generator-storage-rishi-2026

# If not exists, create it
aws s3 mb s3://blog-generator-storage-rishi-2026 --region us-east-1

# Verify creation
aws s3 ls | findstr blog-generator
```

---

## 4️⃣ Enable Amazon Bedrock

### Step 1: Access Bedrock Model Access Page

**Direct Link:** 
```
https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess
```

**Or manually:**
1. Go to: https://console.aws.amazon.com/bedrock/
2. Ensure region is **us-east-1** (top-right)
3. Click **"Model access"** in left sidebar

### Step 2: Request Model Access

1. **Click:** Orange button "Modify model access"
2. **Scroll to:** Anthropic section
3. **Check boxes for:**
   - ✅ Claude 3 Haiku
   - ✅ Claude 3 Sonnet (optional)
   - ✅ Claude 3.5 Sonnet (optional)
4. **Click:** "Next" button

### Step 3: Fill Use Case Form

**Use case category:**
- Select: "Other" or "Content Generation"

**Use case description:**
```
AI-powered blog content generation application for creating 
educational and informative blog posts on various topics.
```

**End user notice:**
- ✅ Check: "I confirm that end users will be notified that they are interacting with AI"

**Click:** "Submit"

### Step 4: Wait for Approval

⏱️ **Time:** Usually 5-15 minutes (can be instant)

**Check status:**
```bash
# List available models
aws bedrock list-foundation-models --region us-east-1 --output table

# Or check in console
# Refresh the Model Access page
```

**Status meanings:**
- 🟡 **In progress** = Waiting for approval
- 🟢 **Access granted** = Ready to use!
- 🔴 **Access denied** = Contact AWS Support

### Step 5: Verify Bedrock Access
```bash
# Test Bedrock connection
aws bedrock list-foundation-models --region us-east-1 --query "modelSummaries[?contains(modelId, 'claude')].modelId"
```

**Expected output:**
```json
[
    "anthropic.claude-3-haiku-20240307-v1:0",
    "anthropic.claude-3-sonnet-20240229-v1:0"
]
```

---

## 5️⃣ Testing Options

### 🌐 Option A: Web Interface (Recommended)

#### Step 1: Start Web Server
```bash
python web_app.py
```

**Expected output:**
```
======================================================================
🚀 AI Blog Generator Web Interface
======================================================================

🌐 Starting server at http://localhost:5000
📝 Open your browser and navigate to the URL above
```

#### Step 2: Open Browser
```
http://localhost:5000
```

#### Step 3: Generate a Blog
1. **Enter topic:** e.g., "Artificial Intelligence"
2. **Set word count:** e.g., 200
3. **Select format:** Text, HTML, or Markdown
4. **Click:** "✨ Generate Blog"
5. **Wait:** 5-10 seconds
6. **Review:** Generated blog appears below
7. **Save:** Choose local or S3 storage

#### Step 4: Stop Server (When Done)
```
Press CTRL+C in terminal
```

---

### 💻 Option B: Command Line Interface

#### Step 1: Run CLI Tool
```bash
python test_local.py
```

#### Step 2: Follow Prompts
```
📝 Enter blog topic: Artificial Intelligence
📊 Enter word count (50-2000, default 200): 300
📄 Select output format:
  1. Plain Text (default)
  2. HTML
  3. Markdown
Choose (1-3): 1

💾 Save options:
  1. Save to S3
  2. Save locally
  3. Both
  4. Skip saving
Choose (1-4): 2
```

#### Step 3: View Generated Blog
- Blog content appears in terminal
- If saved locally, file created in current directory

---

### 🔌 Option C: REST API

#### Step 1: Start Web Server
```bash
python web_app.py
```

#### Step 2: Test API with cURL

**Generate Blog:**
```bash
curl -X POST http://localhost:5000/api/generate ^
  -H "Content-Type: application/json" ^
  -d "{\"blog_topic\": \"Cloud Computing\", \"word_count\": 250, \"output_format\": \"markdown\"}"
```

**Save Blog:**
```bash
curl -X POST http://localhost:5000/api/save ^
  -H "Content-Type: application/json" ^
  -d "{\"blog\": \"Your content here\", \"metadata\": {\"topic\": \"AI\", \"word_count\": 200, \"format\": \"text\"}, \"save_local\": true, \"save_s3\": false}"
```

#### Step 3: Test API with Python
```python
import requests

# Generate blog
response = requests.post(
    'http://localhost:5000/api/generate',
    json={
        'blog_topic': 'Machine Learning',
        'word_count': 300,
        'output_format': 'markdown'
    }
)

result = response.json()
print(result['blog'])
```

---

## 6️⃣ AWS Lambda Deployment

### Step 1: Update Configuration

**Edit these files and update S3 bucket name:**

**File: `app.py` (line 149)**
```python
s3_bucket = 'your-bucket-name-here'  # Change this
```

**File: `web_app.py` (line 441)**
```python
s3_bucket = 'your-bucket-name-here'  # Change this
```

**File: `deploy_lambda.py` (line 17)**
```python
S3_BUCKET_NAME = "your-bucket-name-here"  # Change this
```

### Step 2: Run Deployment Script
```bash
python deploy_lambda.py
```

**Expected output:**
```
======================================================================
🚀 AWS Lambda Deployment - Blog Generator
======================================================================

📦 Creating deployment package...
   Installing dependencies...
   Adding app.py...
   Creating lambda_function.zip...
✅ Deployment package created: lambda_function.zip

🔐 Checking IAM role: BlogGeneratorLambdaRole...
✅ Using existing role: arn:aws:iam::ACCOUNT:role/BlogGeneratorLambdaRole

🚀 Deploying Lambda function: BlogGeneratorFunction...
✅ Function created: arn:aws:lambda:us-east-1:ACCOUNT:function:BlogGeneratorFunction

🧪 Testing Lambda function...
✅ Test completed!

======================================================================
✅ Deployment completed successfully!
======================================================================
```

### Step 3: Test Lambda Function

#### Test via AWS CLI
```bash
# Using example payload
aws lambda invoke ^
  --function-name BlogGeneratorFunction ^
  --region us-east-1 ^
  --payload "{\"body\":\"{\\\"blog_topic\\\":\\\"AI\\\",\\\"word_count\\\":200,\\\"output_format\\\":\\\"text\\\"}\"}" ^
  response.json

# View response
type response.json
```

#### Test via AWS Console
1. **Go to:** https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions/BlogGeneratorFunction
2. **Click:** "Test" tab
3. **Click:** "Create new event"
4. **Event name:** TestBlog
5. **Paste this payload:**
```json
{
  "body": "{\"blog_topic\":\"Artificial Intelligence\",\"word_count\":200,\"output_format\":\"text\"}"
}
```
6. **Click:** "Save"
7. **Click:** "Test" button
8. **View:** Execution results

### Step 4: View Lambda Logs
```bash
# Tail logs in real-time
aws logs tail /aws/lambda/BlogGeneratorFunction --follow --region us-east-1

# View recent logs
aws logs tail /aws/lambda/BlogGeneratorFunction --since 1h --region us-east-1
```

### Step 5: View Generated Blogs in S3
```bash
# List all blogs
aws s3 ls s3://blog-generator-storage-rishi-2026/blog-output/

# Download a specific blog
aws s3 cp s3://blog-generator-storage-rishi-2026/blog-output/20260227_143052.txt ./

# Download all blogs
aws s3 sync s3://blog-generator-storage-rishi-2026/blog-output/ ./downloaded_blogs/
```

---

## 7️⃣ Troubleshooting

### Issue 1: "No module named 'boto3'"
```bash
# Install dependencies
pip install boto3 botocore flask
```

### Issue 2: "AWS credentials not found"
```bash
# Configure AWS
aws configure

# Or set environment variables
set AWS_ACCESS_KEY_ID=your_key_id
set AWS_SECRET_ACCESS_KEY=your_secret_key
set AWS_DEFAULT_REGION=us-east-1
```

### Issue 3: "Bedrock access denied"
```bash
# Enable model access in console
# Go to: https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess
# Click: Modify model access
# Select: Claude 3 Haiku
# Submit use case form
```

### Issue 4: "S3 bucket not found"
```bash
# Create bucket
aws s3 mb s3://your-bucket-name --region us-east-1

# Or update bucket name in code files
```

### Issue 5: "Port 5000 already in use"
```bash
# Find and kill process using port 5000
netstat -ano | findstr :5000
taskkill /PID <PID_NUMBER> /F

# Or use different port (edit web_app.py line 579)
```

### Issue 6: Lambda deployment fails
```bash
# Check permissions
aws sts get-caller-identity

# Ensure you have these permissions:
# - lambda:CreateFunction
# - lambda:UpdateFunctionCode
# - iam:CreateRole
# - iam:AttachRolePolicy
```

### Issue 7: Lambda timeout
```bash
# Increase timeout in deploy_lambda.py (line 19)
TIMEOUT = 300  # Increase to 600 or more

# Or update existing function
aws lambda update-function-configuration ^
  --function-name BlogGeneratorFunction ^
  --timeout 600 ^
  --region us-east-1
```

---

## 📊 Quick Command Reference

### Setup Commands
```bash
# Install dependencies
pip install -r requirements.txt

# Configure AWS
aws configure

# Create S3 bucket
aws s3 mb s3://your-bucket-name --region us-east-1

# Verify AWS identity
aws sts get-caller-identity
```

### Testing Commands
```bash
# Web interface
python web_app.py

# CLI tool
python test_local.py

# Deploy Lambda
python deploy_lambda.py
```

### AWS Commands
```bash
# List S3 blogs
aws s3 ls s3://blog-generator-storage-rishi-2026/blog-output/

# Invoke Lambda
aws lambda invoke --function-name BlogGeneratorFunction --payload '{"body":"..."}' response.json

# View logs
aws logs tail /aws/lambda/BlogGeneratorFunction --follow

# List Bedrock models
aws bedrock list-foundation-models --region us-east-1
```

### File Operations
```bash
# Download from S3
aws s3 cp s3://bucket/blog-output/file.txt ./

# Upload to S3
aws s3 cp myfile.txt s3://bucket/blog-output/

# Sync directory
aws s3 sync ./local-folder/ s3://bucket/blog-output/
```

---

## 🎯 Complete Workflow Example

### End-to-End Test
```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Configure AWS
aws configure
# Enter your credentials

# 3. Verify connection
aws sts get-caller-identity

# 4. Create S3 bucket (if needed)
aws s3 mb s3://my-blog-bucket --region us-east-1

# 5. Update bucket name in app.py, web_app.py, deploy_lambda.py
# (Edit files manually)

# 6. Enable Bedrock
# (Go to console and enable Claude 3 Haiku)

# 7. Test locally
python web_app.py
# Open http://localhost:5000 and generate a blog

# 8. Deploy to Lambda
python deploy_lambda.py

# 9. Test Lambda
aws lambda invoke --function-name BlogGeneratorFunction --payload file://example_payloads.json response.json

# 10. View results
type response.json
aws s3 ls s3://my-blog-bucket/blog-output/
```

---

## 💰 Cost Breakdown

### Bedrock Costs (Claude 3 Haiku)
- Input: $0.25 per 1M tokens
- Output: $1.25 per 1M tokens
- **Per 200-word blog:** ~$0.001 (less than 1 cent)

### S3 Costs
- Storage: $0.023 per GB/month
- **For 1000 blogs (~5MB):** ~$0.0001/month

### Lambda Costs
- First 1M requests/month: FREE
- After: $0.20 per 1M requests
- **For personal use:** Essentially FREE

### Total Monthly Cost (1000 blogs)
- **~$1 - $2 per month**

---

## 📞 Support Resources

### Documentation
- **Project README:** README.md
- **Quick Start:** QUICKSTART.md
- **All Links:** LINKS.md
- **Bedrock Setup:** BEDROCK_SETUP.md

### AWS Console Links
- **Bedrock:** https://console.aws.amazon.com/bedrock/
- **S3:** https://s3.console.aws.amazon.com/s3/
- **Lambda:** https://console.aws.amazon.com/lambda/
- **CloudWatch:** https://console.aws.amazon.com/cloudwatch/

### AWS Documentation
- **Bedrock Guide:** https://docs.aws.amazon.com/bedrock/
- **Lambda Guide:** https://docs.aws.amazon.com/lambda/
- **S3 Guide:** https://docs.aws.amazon.com/s3/

### Get Help
- **AWS Support:** https://console.aws.amazon.com/support/home
- **Bedrock FAQ:** https://aws.amazon.com/bedrock/faqs/

---

## ✅ Completion Checklist

- [ ] Python 3.9+ installed
- [ ] AWS account created
- [ ] AWS CLI configured (`aws configure`)
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] S3 bucket created or name updated in code
- [ ] Bedrock model access enabled (Claude 3 Haiku)
- [ ] Web interface tested (`python web_app.py`)
- [ ] CLI tool tested (`python test_local.py`)
- [ ] Lambda deployed (`python deploy_lambda.py`)
- [ ] Lambda function tested
- [ ] Blogs generated and saved to S3

---

**🎉 Congratulations! Your AI Blog Generator is ready to use!**

**Start generating amazing blogs now!** 🚀
