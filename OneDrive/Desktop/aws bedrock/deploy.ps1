###############################################################################
# AI Assistant - Production Deployment Script (PowerShell)
# Deploys the AI Assistant to AWS Lambda with API Gateway
###############################################################################

# Configuration
$ProjectName = "ai-assistant"
$StackName = "$ProjectName-stack"
$Region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }
$Environment = if ($env:ENVIRONMENT) { $env:ENVIRONMENT } else { "production" }

# Helper functions
function Write-Header {
    param($Message)
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Info {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param($Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check prerequisites
function Check-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    # Check AWS CLI
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Error "AWS CLI not found. Please install it first."
        exit 1
    }
    Write-Success "AWS CLI found"
    
    # Check Python
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Error "Python not found. Please install it first."
        exit 1
    }
    Write-Success "Python found"
    
    # Check pip
    if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
        Write-Error "pip not found. Please install it first."
        exit 1
    }
    Write-Success "pip found"
    
    # Check AWS credentials
    try {
        $accountInfo = aws sts get-caller-identity --output json | ConvertFrom-Json
        Write-Success "AWS credentials configured"
        Write-Info "AWS Account ID: $($accountInfo.Account)"
        Write-Info "AWS Region: $Region"
    }
    catch {
        Write-Error "AWS credentials not configured. Run 'aws configure'"
        exit 1
    }
}

# Create deployment package
function Create-DeploymentPackage {
    Write-Header "Creating Lambda Deployment Package"
    
    # Clean up old deployment artifacts
    Write-Info "Cleaning up old deployment artifacts..."
    if (Test-Path "lambda_package") {
        Remove-Item -Recurse -Force lambda_package -ErrorAction SilentlyContinue
    }
    if (Test-Path "lambda_deployment.zip") {
        try {
            Remove-Item -Force lambda_deployment.zip -ErrorAction Stop
        }
        catch {
            Write-Warning "Could not remove lambda_deployment.zip - it may be locked by another process"
            Write-Info "Waiting 3 seconds and retrying..."
            Start-Sleep -Seconds 3
            Remove-Item -Force lambda_deployment.zip -ErrorAction Stop
        }
    }
    
    # Create package directory
    New-Item -ItemType Directory -Path "lambda_package" -Force | Out-Null
    
    # Copy Lambda function
    Write-Info "Copying Lambda function code..."
    Copy-Item "lambda_function.py" "lambda_package/"
    
    # Install dependencies with upgrade flag to resolve conflicts
    Write-Info "Installing dependencies..."
    pip install -r requirements_lambda.txt -t lambda_package/ --upgrade --no-warn-script-location --quiet
    
    # Create deployment zip
    Write-Info "Creating deployment package..."
    Compress-Archive -Path "lambda_package\*" -DestinationPath "lambda_deployment.zip" -Force
    
    # Clean up package directory
    Remove-Item -Recurse -Force lambda_package
    
    $packageSize = (Get-Item lambda_deployment.zip).Length / 1MB
    Write-Success "Deployment package created: lambda_deployment.zip ($([math]::Round($packageSize, 2)) MB)"
}

# Deploy CloudFormation stack
function Deploy-CloudFormation {
    Write-Header "Deploying CloudFormation Stack"
    
    Write-Info "Stack Name: $StackName"
    Write-Info "Environment: $Environment"
    
    # Check if stack exists
    $stackExists = $false
    try {
        $stackInfo = aws cloudformation describe-stacks --stack-name $StackName --region $Region 2>&1
        if ($LASTEXITCODE -eq 0) {
            $stackExists = $true
            Write-Warning "Stack already exists. Updating..."
            $operation = "update-stack"
        }
    }
    catch {
        # Stack doesn't exist
    }
    
    if (-not $stackExists) {
        Write-Info "Creating new stack..."
        $operation = "create-stack"
    }
    
    # Deploy stack
    $params = @(
        "--stack-name", $StackName,
        "--template-body", "file://cloudformation-template.yaml",
        "--parameters",
        "ParameterKey=ProjectName,ParameterValue=$ProjectName",
        "ParameterKey=BedrockRegion,ParameterValue=$Region",
        "ParameterKey=Environment,ParameterValue=$Environment",
        "--capabilities", "CAPABILITY_NAMED_IAM",
        "--region", $Region,
        "--tags",
        "Key=Project,Value=$ProjectName",
        "Key=Environment,Value=$Environment",
        "Key=ManagedBy,Value=CloudFormation"
    )
    
    aws cloudformation $operation @params
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to $operation stack. Check AWS console for details."
        throw "CloudFormation deployment failed"
    }
    
    if ($operation -eq "create-stack") {
        Write-Info "Waiting for stack creation to complete (this may take 5-10 minutes)..."
        aws cloudformation wait stack-create-complete --stack-name $StackName --region $Region
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Stack creation failed or timed out"
            throw "Stack creation failed"
        }
    }
    else {
        Write-Info "Waiting for stack update to complete..."
        $waitResult = aws cloudformation wait stack-update-complete --stack-name $StackName --region $Region 2>&1
        
        if ($LASTEXITCODE -ne 0 -and $waitResult -notmatch "No updates") {
            Write-Warning "Stack update may have failed or no changes detected"
        }
    }
    
    Write-Success "CloudFormation stack deployed successfully"
}

# Update Lambda function code
function Update-LambdaCode {
    Write-Header "Updating Lambda Function Code"
    
    # Get Lambda function name from CloudFormation stack
    try {
        $outputs = aws cloudformation describe-stacks --stack-name $StackName --region $Region --output json 2>&1 | ConvertFrom-Json
        
        if (-not $outputs.Stacks -or $outputs.Stacks.Count -eq 0) {
            Write-Error "Stack exists but no stack information found"
            throw "Failed to get stack outputs"
        }
        
        $functionName = ($outputs.Stacks[0].Outputs | Where-Object { $_.OutputKey -eq "LambdaFunctionName" }).OutputValue
        
        if (-not $functionName) {
            Write-Error "Lambda function name not found in stack outputs"
            throw "Missing Lambda function name"
        }
        
        Write-Info "Function Name: $functionName"
    }
    catch {
        Write-Error "Failed to get Lambda function name from stack: $_"
        throw
    }
    
    # Update function code
    Write-Info "Uploading Lambda deployment package..."
    aws lambda update-function-code `
        --function-name $functionName `
        --zip-file fileb://lambda_deployment.zip `
        --region $Region `
        --output json | Out-Null
    
    # Wait for update to complete
    Write-Info "Waiting for function update to complete..."
    aws lambda wait function-updated --function-name $functionName --region $Region
    
    Write-Success "Lambda function code updated successfully"
}

# Get stack outputs
function Get-StackOutputs {
    Write-Header "Deployment Information"
    
    # Get outputs
    $outputs = aws cloudformation describe-stacks --stack-name $StackName --region $Region --output json | ConvertFrom-Json
    $stackOutputs = $outputs.Stacks[0].Outputs
    
    $apiEndpoint = ($stackOutputs | Where-Object { $_.OutputKey -eq "APIEndpoint" }).OutputValue
    $s3Bucket = ($stackOutputs | Where-Object { $_.OutputKey -eq "S3BucketName" }).OutputValue
    $lambdaArn = ($stackOutputs | Where-Object { $_.OutputKey -eq "LambdaFunctionArn" }).OutputValue
    
    Write-Host "API Endpoint:"
    Write-Host "  $apiEndpoint" -ForegroundColor White
    Write-Host ""
    Write-Host "S3 Bucket:"
    Write-Host "  $s3Bucket" -ForegroundColor White
    Write-Host ""
    Write-Host "Lambda Function ARN:"
    Write-Host "  $lambdaArn" -ForegroundColor White
    Write-Host ""
    
    # Save to file
    $deploymentInfo = @"
AI Assistant Deployment Information
====================================

Deployment Date: $(Get-Date)
Environment: $Environment
Region: $Region
Stack Name: $StackName

API Endpoint: $apiEndpoint
S3 Bucket: $s3Bucket
Lambda Function ARN: $lambdaArn

PowerShell Test Command:
`$body = @{
    user_input = "What is Python?"
    response_type = "general"
} | ConvertTo-Json

Invoke-RestMethod -Uri "$apiEndpoint" -Method Post -Body `$body -ContentType "application/json"

Curl Test Command:
curl -X POST $apiEndpoint \
  -H "Content-Type: application/json" \
  -d '{\"user_input\": \"What is Python?\", \"response_type\": \"general\"}'

"@
    
    $deploymentInfo | Out-File -FilePath "deployment-info.txt" -Encoding UTF8
    
    Write-Success "Deployment information saved to deployment-info.txt"
    
    return $apiEndpoint
}

# Test deployment
function Test-Deployment {
    param($ApiEndpoint)
    
    Write-Header "Testing Deployment"
    
    Write-Info "Testing API endpoint..."
    Write-Info "Endpoint: $ApiEndpoint"
    
    try {
        $body = @{
            user_input = "Hello, this is a test"
            response_type = "general"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $ApiEndpoint -Method Post -Body $body -ContentType "application/json"
        
        Write-Success "API test successful!"
        $response | ConvertTo-Json -Depth 5
    }
    catch {
        Write-Error "API test failed: $_"
    }
}

# Cleanup
function Cleanup {
    Write-Header "Cleaning Up"
    
    Write-Info "Removing deployment package..."
    if (Test-Path "lambda_deployment.zip") {
        Remove-Item -Force lambda_deployment.zip
    }
    
    Write-Success "Cleanup complete"
}

# Main deployment flow
function Main {
    Write-Header "AI Assistant - Production Deployment"
    
    Write-Info "Starting deployment process..."
    
    try {
        Check-Prerequisites
        Create-DeploymentPackage
        Deploy-CloudFormation
        Update-LambdaCode
        $apiEndpoint = Get-StackOutputs
        
        # Optional: Test deployment
        $test = Read-Host "Do you want to test the deployment? (y/n)"
        if ($test -eq 'y' -or $test -eq 'Y') {
            Test-Deployment -ApiEndpoint $apiEndpoint
        }
        
        Cleanup
        
        Write-Header "Deployment Complete!"
        Write-Success "Your AI Assistant is now deployed and ready to use!"
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Check deployment-info.txt for endpoint details"
        Write-Host "2. Test the API using the provided commands"
        Write-Host "3. Monitor logs in CloudWatch"
        Write-Host "4. Set up custom domain (optional)"
        Write-Host ""
    }
    catch {
        Write-Error "Deployment failed: $_"
        exit 1
    }
}

# Run main function
Main
