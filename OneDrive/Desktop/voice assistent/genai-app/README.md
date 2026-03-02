# GenAI Chatbot

AI-powered chatbot application using AWS Bedrock Knowledge Base for retrieval-augmented generation (RAG).

## Architecture

- **FastAPI** - Modern web framework for building APIs
- **AWS Bedrock** - Foundation models and Knowledge Base
- **AWS S3** - Document storage
- **AWS ECS Fargate** - Serverless container deployment
- **OpenSearch Serverless** - Vector database for knowledge base
- **Terraform** - Infrastructure as Code

## Project Structure

```
genai-app/
├── app/
│   ├── main.py              # FastAPI application
│   ├── routes.py            # API endpoints
│   ├── bedrock_service.py   # Bedrock integration
│   └── s3_service.py        # S3 integration
├── terraform/
│   ├── main.tf              # Terraform configuration
│   ├── variables.tf         # Input variables
│   ├── s3.tf               # S3 buckets
│   ├── ecs.tf              # ECS cluster and services
│   ├── iam.tf              # IAM roles and policies
│   └── bedrock.tf          # Bedrock Knowledge Base
├── .github/workflows/
│   └── deploy.yml          # CI/CD pipeline
├── Dockerfile              # Container image
└── requirements.txt        # Python dependencies
```

## API Endpoints

### Health Check
```bash
GET /health
```

### Chat
```bash
POST /api/v1/chat
{
  "query": "What is the company's revenue?",
  "session_id": "optional-session-id",
  "use_kb": true
}
```

### Retrieve Documents
```bash
POST /api/v1/retrieve
{
  "query": "financial data",
  "max_results": 5
}
```

### Upload File
```bash
POST /api/v1/upload
Content-Type: multipart/form-data
file: <file>
```

### List Files
```bash
GET /api/v1/files?prefix=uploads
```

### Delete File
```bash
DELETE /api/v1/files/{s3_key}
```

## Local Development

### Prerequisites
- Python 3.11+
- AWS Account with appropriate permissions
- Docker (optional)

### Setup

1. **Clone the repository**
```bash
git clone <repository-url>
cd genai-app
```

2. **Create virtual environment**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env with your AWS credentials and configuration
```

5. **Run the application**
```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`
- API Documentation: `http://localhost:8000/docs`
- Alternative docs: `http://localhost:8000/redoc`

### Docker Development

1. **Build Docker image**
```bash
docker build -t genai-chatbot .
```

2. **Run container**
```bash
docker run -p 8000:8000 \
  -e AWS_REGION=us-east-1 \
  -e BEDROCK_KB_ID=your-kb-id \
  -e S3_BUCKET_NAME=your-bucket \
  genai-chatbot
```

## Infrastructure Deployment

### Prerequisites
- Terraform 1.0+
- AWS CLI configured
- ECR repository created

### Deploy with Terraform

1. **Initialize Terraform**
```bash
cd terraform
terraform init
```

2. **Configure variables**
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

3. **Plan deployment**
```bash
terraform plan
```

4. **Apply infrastructure**
```bash
terraform apply
```

### Infrastructure Components

The Terraform configuration creates:
- VPC with public and private subnets
- Application Load Balancer
- ECS Fargate cluster and service
- S3 buckets for documents and KB source
- OpenSearch Serverless collection
- Bedrock Knowledge Base
- IAM roles and policies
- CloudWatch log groups
- Auto-scaling configuration

## CI/CD Pipeline

The GitHub Actions workflow automates:

1. **Lint and Test** - Code quality checks
2. **Build and Push** - Docker image to ECR
3. **Deploy to ECS** - Update ECS service
4. **Terraform Plan** - Infrastructure changes (on PRs)
5. **Terraform Apply** - Apply changes (on main)

### Required GitHub Secrets

Configure these secrets in your repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Workflow Triggers

- **Push to main/develop** - Full deployment
- **Pull Request** - Lint, test, and Terraform plan
- **Manual** - Workflow dispatch

## Bedrock Knowledge Base Setup

1. **Upload documents to S3**
```bash
aws s3 cp your-documents/ s3://your-kb-source-bucket/ --recursive
```

2. **Sync Knowledge Base**
```bash
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id your-kb-id \
  --data-source-id your-data-source-id
```

3. **Monitor ingestion status**
```bash
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id your-kb-id \
  --data-source-id your-data-source-id
```

## Monitoring

### CloudWatch Logs
```bash
aws logs tail /ecs/genai-chatbot-dev --follow
```

### ECS Service Status
```bash
aws ecs describe-services \
  --cluster genai-chatbot-cluster-dev \
  --services genai-chatbot-service-dev
```

### Application Metrics
- CPU utilization
- Memory utilization
- Request count
- Response time
- Error rate

## Security Best Practices

- ✅ IAM roles with least privilege
- ✅ S3 bucket encryption at rest
- ✅ VPC with private subnets for ECS tasks
- ✅ Security groups restricting traffic
- ✅ Secrets stored in environment variables
- ✅ HTTPS/TLS for API endpoints
- ✅ Container running as non-root user

## Cost Optimization

- ECS Fargate Spot for non-production
- S3 lifecycle policies for old files
- Auto-scaling based on demand
- CloudWatch log retention policies
- OpenSearch Serverless for on-demand scaling

## Troubleshooting

### Application won't start
- Check CloudWatch logs for errors
- Verify environment variables
- Ensure IAM roles have correct permissions

### Knowledge Base retrieval fails
- Verify KB is created and synced
- Check IAM permissions for Bedrock
- Ensure documents are in S3

### ECS tasks failing
- Check task definition
- Verify ECR image exists
- Review security group rules
- Check subnet routing

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
