#!/bin/bash
###############################################################################
# AI Assistant - Production Deployment Script
# Deploys the AI Assistant to AWS Lambda with API Gateway
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ai-assistant"
STACK_NAME="${PROJECT_NAME}-stack"
REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-production}"

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "=========================================================================="
    echo "  $1"
    echo "=========================================================================="
    echo ""
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install it first."
        exit 1
    fi
    print_success "AWS CLI found"
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 not found. Please install it first."
        exit 1
    fi
    print_success "Python 3 found"
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 not found. Please install it first."
        exit 1
    fi
    print_success "pip3 found"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure'"
        exit 1
    fi
    print_success "AWS credentials configured"
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_info "AWS Account ID: $ACCOUNT_ID"
    print_info "AWS Region: $REGION"
}

# Create deployment package
create_deployment_package() {
    print_header "Creating Lambda Deployment Package"
    
    # Clean up old deployment artifacts
    print_info "Cleaning up old deployment artifacts..."
    rm -rf lambda_package
    rm -f lambda_deployment.zip
    
    # Create package directory
    mkdir -p lambda_package
    
    # Copy Lambda function
    print_info "Copying Lambda function code..."
    cp lambda_function.py lambda_package/
    
    # Install dependencies
    print_info "Installing dependencies..."
    pip3 install -r requirements_lambda.txt -t lambda_package/ --quiet
    
    # Create deployment zip
    print_info "Creating deployment package..."
    cd lambda_package
    zip -r ../lambda_deployment.zip . -q
    cd ..
    
    # Clean up package directory
    rm -rf lambda_package
    
    PACKAGE_SIZE=$(du -h lambda_deployment.zip | cut -f1)
    print_success "Deployment package created: lambda_deployment.zip ($PACKAGE_SIZE)"
}

# Deploy CloudFormation stack
deploy_cloudformation() {
    print_header "Deploying CloudFormation Stack"
    
    print_info "Stack Name: $STACK_NAME"
    print_info "Environment: $ENVIRONMENT"
    
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null; then
        print_warning "Stack already exists. Updating..."
        OPERATION="update-stack"
    else
        print_info "Creating new stack..."
        OPERATION="create-stack"
    fi
    
    # Deploy stack
    aws cloudformation $OPERATION \
        --stack-name $STACK_NAME \
        --template-body file://cloudformation-template.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
            ParameterKey=BedrockRegion,ParameterValue=$REGION \
            ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION \
        --tags \
            Key=Project,Value=$PROJECT_NAME \
            Key=Environment,Value=$ENVIRONMENT \
            Key=ManagedBy,Value=CloudFormation
    
    if [ "$OPERATION" = "create-stack" ]; then
        print_info "Waiting for stack creation to complete..."
        aws cloudformation wait stack-create-complete \
            --stack-name $STACK_NAME \
            --region $REGION
    else
        print_info "Waiting for stack update to complete..."
        aws cloudformation wait stack-update-complete \
            --stack-name $STACK_NAME \
            --region $REGION 2>/dev/null || true
    fi
    
    print_success "CloudFormation stack deployed successfully"
}

# Update Lambda function code
update_lambda_code() {
    print_header "Updating Lambda Function Code"
    
    # Get Lambda function name from CloudFormation stack
    FUNCTION_NAME=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionName`].OutputValue' \
        --output text)
    
    print_info "Function Name: $FUNCTION_NAME"
    
    # Update function code
    print_info "Uploading Lambda deployment package..."
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://lambda_deployment.zip \
        --region $REGION \
        --output json > /dev/null
    
    # Wait for update to complete
    print_info "Waiting for function update to complete..."
    aws lambda wait function-updated \
        --function-name $FUNCTION_NAME \
        --region $REGION
    
    print_success "Lambda function code updated successfully"
}

# Get stack outputs
get_stack_outputs() {
    print_header "Deployment Information"
    
    # Get outputs
    API_ENDPOINT=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' \
        --output text)
    
    S3_BUCKET=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
        --output text)
    
    LAMBDA_ARN=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionArn`].OutputValue' \
        --output text)
    
    echo "API Endpoint:"
    echo "  $API_ENDPOINT"
    echo ""
    echo "S3 Bucket:"
    echo "  $S3_BUCKET"
    echo ""
    echo "Lambda Function ARN:"
    echo "  $LAMBDA_ARN"
    echo ""
    
    # Save to file
    cat > deployment-info.txt <<EOF
AI Assistant Deployment Information
====================================

Deployment Date: $(date)
Environment: $ENVIRONMENT
Region: $REGION
Stack Name: $STACK_NAME

API Endpoint: $API_ENDPOINT
S3 Bucket: $S3_BUCKET
Lambda Function ARN: $LAMBDA_ARN

Test Command:
curl -X POST $API_ENDPOINT \\
  -H "Content-Type: application/json" \\
  -d '{"user_input": "What is Python?", "response_type": "general"}'

EOF
    
    print_success "Deployment information saved to deployment-info.txt"
}

# Test deployment
test_deployment() {
    print_header "Testing Deployment"
    
    API_ENDPOINT=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' \
        --output text)
    
    print_info "Testing API endpoint..."
    print_info "Endpoint: $API_ENDPOINT"
    
    RESPONSE=$(curl -s -X POST $API_ENDPOINT \
        -H "Content-Type: application/json" \
        -d '{"user_input": "Hello, this is a test", "response_type": "general"}')
    
    if echo "$RESPONSE" | grep -q "success"; then
        print_success "API test successful!"
        echo "$RESPONSE" | python3 -m json.tool
    else
        print_error "API test failed"
        echo "$RESPONSE"
    fi
}

# Cleanup
cleanup() {
    print_header "Cleaning Up"
    
    print_info "Removing deployment package..."
    rm -f lambda_deployment.zip
    
    print_success "Cleanup complete"
}

# Main deployment flow
main() {
    print_header "AI Assistant - Production Deployment"
    
    print_info "Starting deployment process..."
    
    check_prerequisites
    create_deployment_package
    deploy_cloudformation
    update_lambda_code
    get_stack_outputs
    
    # Optional: Test deployment
    read -p "Do you want to test the deployment? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_deployment
    fi
    
    cleanup
    
    print_header "Deployment Complete!"
    print_success "Your AI Assistant is now deployed and ready to use!"
    echo ""
    echo "Next steps:"
    echo "1. Check deployment-info.txt for endpoint details"
    echo "2. Test the API using the provided curl command"
    echo "3. Monitor logs in CloudWatch"
    echo "4. Set up custom domain (optional)"
    echo ""
}

# Run main function
main
