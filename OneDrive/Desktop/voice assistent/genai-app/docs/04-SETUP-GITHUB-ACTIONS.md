# Set Up GitHub Actions CI/CD Pipeline

This guide walks you through setting up automated CI/CD using GitHub Actions.

## Prerequisites

- GitHub repository for your project
- AWS account with appropriate permissions
- ECR repository created
- Infrastructure deployed (or ready to deploy)

## Step 1: Push Code to GitHub

### Initialize Git Repository

```bash
cd genai-app

# Initialize git
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: GenAI Chatbot"

# Add remote repository
git remote add origin https://github.com/your-username/genai-chatbot.git

# Push to GitHub
git push -u origin main
```

## Step 2: Configure GitHub Secrets

Navigate to your GitHub repository:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**

### Required Secrets

Add the following secrets:

**AWS_ACCESS_KEY_ID**
- Value: Your AWS access key
- Used for: AWS authentication

**AWS_SECRET_ACCESS_KEY**
- Value: Your AWS secret key
- Used for: AWS authentication

### Optional Secrets (if using)

**API_KEY**
- Value: Your API authentication key
- Used for: API security

**JWT_SECRET_KEY**
- Value: Secret for JWT tokens
- Used for: User authentication

**SLACK_WEBHOOK_URL**
- Value: Webhook for notifications
- Used for: Deployment notifications

## Step 3: Create AWS IAM User for CI/CD

```bash
# Create IAM user
aws iam create-user --user-name github-actions-deployer

# Attach necessary policies
aws iam attach-user-policy \
  --user-name github-actions-deployer \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

aws iam attach-user-policy \
  --user-name github-actions-deployer \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

# Create custom policy for additional permissions
cat > github-actions-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "logs:*",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-user-policy \
  --user-name github-actions-deployer \
  --policy-name GitHubActionsPolicy \
  --policy-document file://github-actions-policy.json

# Create access keys
aws iam create-access-key --user-name github-actions-deployer
```

Save the access key ID and secret access key as GitHub secrets.

## Step 4: Customize Workflow

Edit `.github/workflows/deploy.yml`:

```yaml
env:
  AWS_REGION: us-east-1  # Change to your region
  ECR_REPOSITORY: genai-chatbot  # Your ECR repo name
  ECS_CLUSTER: genai-chatbot-cluster-dev  # Your cluster name
  ECS_SERVICE: genai-chatbot-service-dev  # Your service name
  CONTAINER_NAME: genai-chatbot-container
```

## Step 5: Test the Workflow

### Trigger on Push

```bash
# Make a change
echo "# Test" >> README.md

# Commit and push
git add README.md
git commit -m "Test CI/CD pipeline"
git push origin main
```

### Monitor Workflow

1. Go to your GitHub repository
2. Click on **Actions** tab
3. Click on the running workflow
4. Monitor each job:
   - ✅ Lint and Test
   - ✅ Build and Push
   - ✅ Deploy to ECS

## Step 6: Branch Protection (Optional)

Set up branch protection rules:

1. Go to **Settings** → **Branches**
2. Click **Add rule**
3. Branch name pattern: `main`
4. Enable:
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging

## Workflow Overview

### Jobs Breakdown

**1. Lint and Test**
- Runs on: All pushes and PRs
- Actions:
  - Check code formatting with Black
  - Lint with Flake8
  - Run unit tests (if available)

**2. Build and Push**
- Runs on: Pushes to main/develop
- Actions:
  - Build Docker image
  - Tag with git SHA and branch
  - Push to Amazon ECR
  - Cache layers for faster builds

**3. Deploy to ECS**
- Runs on: Pushes to main/develop
- Actions:
  - Download current task definition
  - Update with new image
  - Deploy to ECS cluster
  - Wait for service stability

**4. Terraform Plan**
- Runs on: Pull requests
- Actions:
  - Initialize Terraform
  - Validate configuration
  - Generate plan
  - Comment plan on PR

**5. Terraform Apply**
- Runs on: Pushes to main
- Actions:
  - Apply infrastructure changes
  - Update resources automatically

## Advanced Configuration

### Multi-Environment Deployment

Create separate workflows for different environments:

**.github/workflows/deploy-dev.yml**
```yaml
name: Deploy to Development

on:
  push:
    branches: [develop]

env:
  ENVIRONMENT: dev
  ECS_CLUSTER: genai-chatbot-cluster-dev
```

**.github/workflows/deploy-prod.yml**
```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

env:
  ENVIRONMENT: prod
  ECS_CLUSTER: genai-chatbot-cluster-prod
```

### Manual Approval for Production

Add manual approval step:

```yaml
jobs:
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://api.yourdomain.com
    needs: build-and-push
    
    steps:
      # ... deployment steps
```

Then configure environment protection in GitHub:
1. **Settings** → **Environments** → **New environment**
2. Name: `production`
3. Enable **Required reviewers**
4. Add reviewers who must approve

### Slack Notifications

Add notification step:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Deployment to ${{ env.ENVIRONMENT }}'
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
    fields: repo,message,commit,author,action,eventName,ref,workflow
```

### Rollback on Failure

Add automatic rollback:

```yaml
- name: Rollback on failure
  if: failure()
  run: |
    aws ecs update-service \
      --cluster ${{ env.ECS_CLUSTER }} \
      --service ${{ env.ECS_SERVICE }} \
      --force-new-deployment \
      --task-definition previous-task-def
```

## Troubleshooting

### Common Issues

**Issue: AWS credentials not working**
```bash
# Verify secrets are set correctly
# Check IAM user permissions
aws sts get-caller-identity
```

**Issue: Docker build fails**
```bash
# Check Dockerfile syntax
docker build -t test .

# Review build logs in GitHub Actions
```

**Issue: ECS deployment timeout**
```bash
# Check ECS service events
aws ecs describe-services \
  --cluster $CLUSTER \
  --services $SERVICE

# Increase wait time in workflow
wait-for-service-stability: true
```

### Enable Debug Logging

Add to workflow:

```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## Best Practices

1. **Use Semantic Versioning**: Tag releases with version numbers
2. **Separate Environments**: dev, staging, production
3. **Manual Approval**: For production deployments
4. **Automated Rollback**: On deployment failures
5. **Notifications**: Alert team of deployment status
6. **Security Scanning**: Scan Docker images for vulnerabilities
7. **Secrets Management**: Never commit secrets to repository

## Next Steps

- ✅ CI/CD pipeline configured
- 🚀 [Deploy infrastructure](./01-DEPLOY-INFRASTRUCTURE.md)
- 🧪 [Test locally](./02-TEST-LOCALLY.md)
- ⚙️ [Customize config](./03-CUSTOMIZE-CONFIG.md)
- ✨ [Add advanced features](./05-ADD-FEATURES.md)
