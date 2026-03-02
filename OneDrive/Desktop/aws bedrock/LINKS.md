# 🔗 Complete Links & Resources - AI Blog Generator

## 📍 Local Application URLs

### Web Interface
- **Main UI:** http://localhost:5000
- **Health Check:** http://localhost:5000/
- **API Generate Endpoint:** http://localhost:5000/api/generate
- **API Save Endpoint:** http://localhost:5000/api/save

### How to Start
```bash
python web_app.py
```

---

## ☁️ AWS Console Links

### Amazon Bedrock
- **Bedrock Home:** https://console.aws.amazon.com/bedrock/
- **Model Access (us-east-1):** https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess
- **Playgrounds:** https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/text-playground
- **Foundation Models:** https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/foundation-models

### Amazon S3
- **S3 Home:** https://s3.console.aws.amazon.com/s3/
- **Your Bucket:** https://s3.console.aws.amazon.com/s3/buckets/blog-generator-storage-rishi-2026
- **Blog Output Folder:** https://s3.console.aws.amazon.com/s3/buckets/blog-generator-storage-rishi-2026?prefix=blog-output/

### AWS Lambda
- **Lambda Home:** https://console.aws.amazon.com/lambda/home?region=us-east-1
- **Your Function:** https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions/BlogGeneratorFunction
- **Function Code:** https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions/BlogGeneratorFunction?tab=code
- **Function Test:** https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions/BlogGeneratorFunction?tab=testing
- **Function Configuration:** https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions/BlogGeneratorFunction?tab=configure

### IAM (Identity & Access Management)
- **IAM Home:** https://console.aws.amazon.com/iam/
- **Your Role:** https://console.aws.amazon.com/iam/home#/roles/BlogGeneratorLambdaRole
- **Policies:** https://console.aws.amazon.com/iam/home#/policies
- **Users:** https://console.aws.amazon.com/iam/home#/users

### CloudWatch (Logs & Monitoring)
- **CloudWatch Home:** https://console.aws.amazon.com/cloudwatch/home?region=us-east-1
- **Lambda Logs:** https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252FBlogGeneratorFunction
- **Log Insights:** https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:logs-insights

### Billing & Cost Management
- **Billing Dashboard:** https://console.aws.amazon.com/billing/home
- **Cost Explorer:** https://console.aws.amazon.com/cost-management/home#/cost-explorer
- **Budgets:** https://console.aws.amazon.com/billing/home#/budgets

---

## 🛠️ AWS CLI Commands

### Bedrock Commands
```bash
# List available foundation models
aws bedrock list-foundation-models --region us-east-1

# Get model details
aws bedrock get-foundation-model --model-identifier anthropic.claude-3-haiku-20240307-v1:0 --region us-east-1

# Invoke model directly
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-3-haiku-20240307-v1:0 \
  --body '{"anthropic_version":"bedrock-2023-05-31","max_tokens":512,"messages":[{"role":"user","content":"Hello"}]}' \
  --region us-east-1 \
  output.json
```

### S3 Commands
```bash
# List bucket contents
aws s3 ls s3://blog-generator-storage-rishi-2026/

# List blog outputs
aws s3 ls s3://blog-generator-storage-rishi-2026/blog-output/

# Download a specific blog
aws s3 cp s3://blog-generator-storage-rishi-2026/blog-output/20260227_143052.md ./

# Download all blogs
aws s3 sync s3://blog-generator-storage-rishi-2026/blog-output/ ./downloaded_blogs/

# Upload a file
aws s3 cp myblog.txt s3://blog-generator-storage-rishi-2026/blog-output/

# Create new bucket
aws s3 mb s3://your-new-bucket-name --region us-east-1

# Delete a file
aws s3 rm s3://blog-generator-storage-rishi-2026/blog-output/filename.txt
```

### Lambda Commands
```bash
# List all functions
aws lambda list-functions --region us-east-1

# Get function details
aws lambda get-function --function-name BlogGeneratorFunction --region us-east-1

# Get function configuration
aws lambda get-function-configuration --function-name BlogGeneratorFunction --region us-east-1

# Invoke function (sync)
aws lambda invoke \
  --function-name BlogGeneratorFunction \
  --region us-east-1 \
  --payload '{"body":"{\"blog_topic\":\"AI\",\"word_count\":200,\"output_format\":\"text\"}"}' \
  response.json

# Invoke function (async)
aws lambda invoke \
  --function-name BlogGeneratorFunction \
  --region us-east-1 \
  --invocation-type Event \
  --payload '{"body":"{\"blog_topic\":\"AI\",\"word_count\":200,\"output_format\":\"text\"}"}' \
  response.json

# Update function code
aws lambda update-function-code \
  --function-name BlogGeneratorFunction \
  --zip-file fileb://lambda_function.zip \
  --region us-east-1

# Delete function
aws lambda delete-function --function-name BlogGeneratorFunction --region us-east-1
```

### CloudWatch Logs Commands
```bash
# Tail logs in real-time
aws logs tail /aws/lambda/BlogGeneratorFunction --follow --region us-east-1

# Get recent log events
aws logs tail /aws/lambda/BlogGeneratorFunction --since 1h --region us-east-1

# List log streams
aws logs describe-log-streams \
  --log-group-name /aws/lambda/BlogGeneratorFunction \
  --region us-east-1

# Get specific log stream
aws logs get-log-events \
  --log-group-name /aws/lambda/BlogGeneratorFunction \
  --log-stream-name '2026/02/27/[$LATEST]abc123' \
  --region us-east-1
```

### IAM Commands
```bash
# Get current user info
aws sts get-caller-identity

# List IAM roles
aws iam list-roles

# Get specific role
aws iam get-role --role-name BlogGeneratorLambdaRole

# List attached policies
aws iam list-attached-role-policies --role-name BlogGeneratorLambdaRole

# Get policy details
aws iam get-role-policy --role-name BlogGeneratorLambdaRole --policy-name BedrockS3Access
```

---

## 🌐 API Testing Examples

### Using cURL

**Generate Text Blog:**
```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{"blog_topic": "Artificial Intelligence", "word_count": 200, "output_format": "text"}'
```

**Generate HTML Blog:**
```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{"blog_topic": "Cloud Computing", "word_count": 300, "output_format": "html"}'
```

**Generate Markdown Blog:**
```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{"blog_topic": "Machine Learning", "word_count": 250, "output_format": "markdown"}'
```

**Save Blog:**
```bash
curl -X POST http://localhost:5000/api/save \
  -H "Content-Type: application/json" \
  -d '{
    "blog": "Your blog content here",
    "metadata": {
      "topic": "AI",
      "word_count": 200,
      "format": "text"
    },
    "save_local": true,
    "save_s3": true
  }'
```

### Using Python Requests

```python
import requests
import json

# Generate blog
response = requests.post(
    'http://localhost:5000/api/generate',
    json={
        'blog_topic': 'Quantum Computing',
        'word_count': 300,
        'output_format': 'markdown'
    }
)

result = response.json()
print(result['blog'])

# Save blog
save_response = requests.post(
    'http://localhost:5000/api/save',
    json={
        'blog': result['blog'],
        'metadata': result['metadata'],
        'save_local': True,
        'save_s3': True
    }
)

print(save_response.json())
```

### Using PowerShell

```powershell
# Generate blog
$body = @{
    blog_topic = "Artificial Intelligence"
    word_count = 200
    output_format = "text"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/api/generate" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body
```

---

## 📚 Documentation & Learning Resources

### AWS Documentation
- **Bedrock User Guide:** https://docs.aws.amazon.com/bedrock/latest/userguide/
- **Bedrock API Reference:** https://docs.aws.amazon.com/bedrock/latest/APIReference/
- **Lambda Developer Guide:** https://docs.aws.amazon.com/lambda/latest/dg/
- **S3 User Guide:** https://docs.aws.amazon.com/s3/
- **IAM User Guide:** https://docs.aws.amazon.com/iam/

### Anthropic Claude Documentation
- **Claude Documentation:** https://docs.anthropic.com/claude/docs
- **API Reference:** https://docs.anthropic.com/claude/reference/
- **Prompt Engineering:** https://docs.anthropic.com/claude/docs/prompt-engineering

### Python & Flask
- **Flask Documentation:** https://flask.palletsprojects.com/
- **Boto3 Documentation:** https://boto3.amazonaws.com/v1/documentation/api/latest/index.html
- **Python Official Docs:** https://docs.python.org/3/

### Tutorials & Guides
- **AWS Bedrock Getting Started:** https://aws.amazon.com/bedrock/getting-started/
- **Lambda Python Tutorial:** https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html
- **S3 Tutorial:** https://docs.aws.amazon.com/AmazonS3/latest/userguide/getting-started.html

---

## 🎓 Additional Resources

### GitHub Repository (If Available)
- **Project Repository:** [Your GitHub URL]
- **Issues:** [Your GitHub Issues URL]
- **Pull Requests:** [Your GitHub PRs URL]

### AWS Pricing
- **Bedrock Pricing:** https://aws.amazon.com/bedrock/pricing/
- **Lambda Pricing:** https://aws.amazon.com/lambda/pricing/
- **S3 Pricing:** https://aws.amazon.com/s3/pricing/
- **Pricing Calculator:** https://calculator.aws/

### AWS Support
- **Support Center:** https://console.aws.amazon.com/support/home
- **Service Health Dashboard:** https://status.aws.amazon.com/
- **AWS Forums:** https://forums.aws.amazon.com/

---

## 🔧 Configuration Files Reference

### Example Lambda Test Payload
File: `example_payloads.json`

```json
{
  "body": "{\"blog_topic\": \"Artificial Intelligence\", \"word_count\": 200, \"output_format\": \"text\"}"
}
```

### Environment Variables
```bash
# For local testing
export AWS_REGION=us-east-1
export S3_BUCKET=blog-generator-storage-rishi-2026
export AWS_PROFILE=default
```

### AWS Credentials File Location
- **Windows:** `C:\Users\USERNAME\.aws\credentials`
- **Linux/Mac:** `~/.aws/credentials`

### AWS Config File Location
- **Windows:** `C:\Users\USERNAME\.aws\config`
- **Linux/Mac:** `~/.aws/config`

---

## 📞 Quick Reference

### Project Files
| File | Purpose | Size |
|------|---------|------|
| `app.py` | Core blog generation logic | 5.7 KB |
| `web_app.py` | Web UI & REST API | 16.1 KB |
| `test_local.py` | CLI testing tool | 4.5 KB |
| `deploy_lambda.py` | AWS deployment script | 7.9 KB |
| `requirements.txt` | Python dependencies | 47 B |
| `README.md` | Main documentation | 7.6 KB |
| `QUICKSTART.md` | Quick start guide | 10.1 KB |
| `LINKS.md` | This file | - |

### Key Commands
```bash
# Start web server
python web_app.py

# Test locally
python test_local.py

# Deploy to AWS
python deploy_lambda.py

# View S3 files
aws s3 ls s3://blog-generator-storage-rishi-2026/blog-output/

# Tail Lambda logs
aws logs tail /aws/lambda/BlogGeneratorFunction --follow
```

### Support Information
- **AWS Account ID:** 335660922845
- **IAM User:** Rishi
- **Default Region:** us-east-1
- **S3 Bucket:** blog-generator-storage-rishi-2026
- **Lambda Function:** BlogGeneratorFunction
- **IAM Role:** BlogGeneratorLambdaRole

---

**Last Updated:** 2026-02-27

**Need Help?** Check the [QUICKSTART.md](QUICKSTART.md) guide or [README.md](README.md) for detailed instructions.
