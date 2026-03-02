# 🚀 Quick Start Guide - AI Blog Generator

## 📋 Table of Contents
- [Installation](#installation)
- [Quick Links](#quick-links)
- [Usage Methods](#usage-methods)
- [AWS Resources](#aws-resources)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)

---

## 🔧 Installation

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure AWS Credentials
```bash
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-east-1`
- Default output format: `json`

### 3. Update S3 Bucket Name
Edit `app.py`, `web_app.py`, and `deploy_lambda.py`:
```python
s3_bucket = 'your-bucket-name-here'  # Replace with your bucket
```

---

## 🔗 Quick Links

### Local Application URLs
| Service | URL | Description |
|---------|-----|-------------|
| **Web Interface** | http://localhost:5000 | Main web UI |
| **API Generate** | http://localhost:5000/api/generate | Blog generation endpoint |
| **API Save** | http://localhost:5000/api/save | Blog save endpoint |

### AWS Console Links
| Service | Link | Purpose |
|---------|------|---------|
| **Bedrock Console** | https://console.aws.amazon.com/bedrock/ | Enable models & manage Bedrock |
| **S3 Console** | https://s3.console.aws.amazon.com/s3/buckets/blog-generator-storage-rishi-2026 | View generated blogs |
| **Lambda Console** | https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/BlogGeneratorFunction | Manage Lambda function |
| **IAM Roles** | https://console.aws.amazon.com/iam/home#/roles/BlogGeneratorLambdaRole | View IAM role |
| **CloudWatch Logs** | https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252FBlogGeneratorFunction | View Lambda logs |

### AWS CLI Commands
```bash
# View S3 bucket contents
aws s3 ls s3://blog-generator-storage-rishi-2026/blog-output/

# Download a blog from S3
aws s3 cp s3://blog-generator-storage-rishi-2026/blog-output/20260227_143052.md ./

# List Lambda functions
aws lambda list-functions --region us-east-1

# Get Lambda function details
aws lambda get-function --function-name BlogGeneratorFunction --region us-east-1

# View Lambda logs
aws logs tail /aws/lambda/BlogGeneratorFunction --follow
```

---

## 💻 Usage Methods

### Method 1: Web Interface (Recommended)

**Start the server:**
```bash
python web_app.py
```

**Access:**
- Open browser: http://localhost:5000
- Fill in the form
- Click "Generate Blog"
- Choose save options

**Features:**
- ✅ Interactive UI
- ✅ Real-time generation
- ✅ Multiple format options
- ✅ Save to S3 or locally

---

### Method 2: Command Line Interface

**Run the CLI tool:**
```bash
python test_local.py
```

**Interactive prompts:**
1. Enter blog topic
2. Enter word count (50-2000)
3. Select format (1=Text, 2=HTML, 3=Markdown)
4. Choose save options (1=S3, 2=Local, 3=Both, 4=Skip)

**Example session:**
```
📝 Enter blog topic: Cloud Computing
📊 Enter word count (50-2000, default 200): 300
📄 Select output format:
  1. Plain Text (default)
  2. HTML
  3. Markdown
Choose (1-3): 3
```

---

### Method 3: REST API

**Start the API server:**
```bash
python web_app.py
```

**Generate Blog:**
```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "blog_topic": "Artificial Intelligence",
    "word_count": 250,
    "output_format": "markdown"
  }'
```

**Response:**
```json
{
  "success": true,
  "blog": "# Artificial Intelligence\n\n...",
  "metadata": {
    "topic": "Artificial Intelligence",
    "word_count": 250,
    "format": "markdown"
  }
}
```

**Save Blog:**
```bash
curl -X POST http://localhost:5000/api/save \
  -H "Content-Type: application/json" \
  -d '{
    "blog": "Your blog content here",
    "metadata": {
      "topic": "AI",
      "word_count": 250,
      "format": "markdown"
    },
    "save_local": true,
    "save_s3": true
  }'
```

---

### Method 4: AWS Lambda

**Deploy to Lambda:**
```bash
python deploy_lambda.py
```

**Invoke via AWS CLI:**
```bash
aws lambda invoke \
  --function-name BlogGeneratorFunction \
  --region us-east-1 \
  --payload '{"body":"{\"blog_topic\":\"Machine Learning\",\"word_count\":200,\"output_format\":\"text\"}"}' \
  response.json

cat response.json
```

**Invoke via AWS Console:**
1. Go to: https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/BlogGeneratorFunction
2. Click "Test" tab
3. Create test event with payload:
```json
{
  "body": "{\"blog_topic\":\"Cloud Computing\",\"word_count\":300,\"output_format\":\"html\"}"
}
```
4. Click "Test" button

---

### Method 5: Python Code Integration

**Import and use directly:**
```python
from app import blog_generate_using_bedrock, save_blog_details_s3

# Generate a blog
blog = blog_generate_using_bedrock(
    blogtopic="Quantum Computing",
    word_count=500,
    output_format="markdown"
)

print(blog)

# Save to S3
save_blog_details_s3(
    s3_key="blog-output/quantum_computing.md",
    s3_bucket="your-bucket-name",
    generate_blog=blog,
    content_type="text/markdown"
)
```

---

## 📚 API Documentation

### POST /api/generate

**Request:**
```json
{
  "blog_topic": "string (required)",
  "word_count": "integer (optional, default: 200, range: 50-2000)",
  "output_format": "string (optional, default: 'text', options: 'text'|'html'|'markdown')"
}
```

**Response:**
```json
{
  "success": true,
  "blog": "Generated blog content...",
  "metadata": {
    "topic": "string",
    "word_count": integer,
    "format": "string"
  }
}
```

### POST /api/save

**Request:**
```json
{
  "blog": "string (required)",
  "metadata": {
    "topic": "string",
    "word_count": integer,
    "format": "string"
  },
  "save_local": "boolean (default: false)",
  "save_s3": "boolean (default: false)"
}
```

**Response:**
```json
{
  "success": true,
  "local_file": "blog_20260227_143052.md",
  "s3_location": "s3://bucket/blog-output/20260227_143052.md"
}
```

---

## 🌐 AWS Resources

### Bedrock Model Information
- **Model ID:** `anthropic.claude-3-haiku-20240307-v1:0`
- **Model Name:** Claude 3 Haiku
- **Provider:** Anthropic
- **Region:** us-east-1
- **Enable Model:** https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

### S3 Bucket Structure
```
s3://blog-generator-storage-rishi-2026/
└── blog-output/
    ├── 20260227_143052.txt
    ├── 20260227_143105.html
    └── 20260227_143210.md
```

### Lambda Configuration
- **Function Name:** BlogGeneratorFunction
- **Runtime:** Python 3.11
- **Handler:** app.lambda_handler
- **Timeout:** 300 seconds
- **Memory:** 512 MB
- **Role:** BlogGeneratorLambdaRole

### IAM Permissions Required
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["bedrock:InvokeModel"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:PutObjectAcl"],
      "Resource": "arn:aws:s3:::your-bucket/*"
    }
  ]
}
```

---

## 🔍 Troubleshooting

### Common Issues

#### 1. AWS Credentials Not Found
```bash
aws configure
```
Enter your Access Key ID and Secret Access Key

#### 2. Bedrock Access Denied
- Go to: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess
- Enable "Claude 3 Haiku" model
- Wait 2-3 minutes for activation

#### 3. S3 Bucket Not Found
```bash
# Create bucket
aws s3 mb s3://your-bucket-name --region us-east-1

# Or update bucket name in code
# Edit: app.py, web_app.py, deploy_lambda.py
```

#### 4. Flask Import Error
```bash
pip install flask>=3.0.0
```

#### 5. Lambda Deployment Fails
```bash
# Check permissions
aws sts get-caller-identity

# Verify IAM permissions
aws iam list-attached-user-policies --user-name YOUR_USERNAME
```

#### 6. Port 5000 Already in Use
```bash
# Kill existing process
# Windows:
Get-Process -Name python | Stop-Process -Force

# Linux/Mac:
killall python
```

---

## 📊 Output Examples

### Text Format
```
Topic: Artificial Intelligence
Word Count: 200
Generated: 2026-02-27 14:30:52
======================================================================

The Future of AI...
```

### HTML Format
```html
<h1>The Future of AI</h1>
<p>Artificial Intelligence is revolutionizing...</p>
<h2>Key Applications</h2>
<p>AI has numerous applications in...</p>
```

### Markdown Format
```markdown
# The Future of AI

Artificial Intelligence is revolutionizing...

## Key Applications

- Healthcare
- Finance
- Transportation
```

---

## 🎯 Quick Commands Cheat Sheet

```bash
# Start web interface
python web_app.py

# Test locally
python test_local.py

# Deploy to Lambda
python deploy_lambda.py

# View S3 blogs
aws s3 ls s3://blog-generator-storage-rishi-2026/blog-output/

# Invoke Lambda
aws lambda invoke --function-name BlogGeneratorFunction --payload file://test_payload.json response.json

# View Lambda logs
aws logs tail /aws/lambda/BlogGeneratorFunction --follow

# Create S3 bucket
aws s3 mb s3://your-bucket-name

# Test API
curl -X POST http://localhost:5000/api/generate -H "Content-Type: application/json" -d '{"blog_topic":"AI"}'
```

---

## 📞 Support & Resources

### Documentation
- **Project README:** [README.md](README.md)
- **AWS Bedrock Docs:** https://docs.aws.amazon.com/bedrock/
- **Claude Model Guide:** https://docs.anthropic.com/claude/docs

### AWS Service Documentation
- **Bedrock:** https://docs.aws.amazon.com/bedrock/latest/userguide/
- **Lambda:** https://docs.aws.amazon.com/lambda/latest/dg/
- **S3:** https://docs.aws.amazon.com/s3/
- **IAM:** https://docs.aws.amazon.com/iam/

---

**Happy Blog Generating! 🎉**
