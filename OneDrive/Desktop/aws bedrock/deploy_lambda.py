#!/usr/bin/env python3
"""
AWS Lambda deployment script for the Blog Generator.
This script packages and deploys/updates the Lambda function.
"""

import boto3
import zipfile
import os
import json
import time
from pathlib import Path

# Configuration
LAMBDA_FUNCTION_NAME = "ai-assistant-function"
LAMBDA_ROLE_NAME = "ai-assistant-lambda-role"
S3_BUCKET_NAME = "ai-assistant-responses-335660922845"
REGION = "us-east-1"
RUNTIME = "python3.11"
HANDLER = "lambda_function.lambda_handler"
TIMEOUT = 30
MEMORY_SIZE = 512

def create_deployment_package():
    """Create a deployment package with the Lambda function and dependencies"""
    print("📦 Creating deployment package...")
    
    # Create a temporary directory for dependencies
    package_dir = Path("lambda_package")
    package_dir.mkdir(exist_ok=True)
    
    # Install dependencies
    print("   Installing dependencies...")
    os.system(f"pip install -r requirements.txt -t {package_dir} --quiet")
    
    # Copy the main app file
    print("   Adding app.py...")
    import shutil
    shutil.copy("app.py", package_dir / "app.py")
    
    # Create ZIP file
    zip_file = "lambda_function.zip"
    print(f"   Creating {zip_file}...")
    
    with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(package_dir):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, package_dir)
                zipf.write(file_path, arcname)
    
    # Clean up
    shutil.rmtree(package_dir)
    
    print(f"✅ Deployment package created: {zip_file}")
    return zip_file

def get_or_create_role(iam_client):
    """Get existing IAM role or create a new one"""
    print(f"\n🔐 Checking IAM role: {LAMBDA_ROLE_NAME}...")
    
    try:
        response = iam_client.get_role(RoleName=LAMBDA_ROLE_NAME)
        role_arn = response['Role']['Arn']
        print(f"✅ Using existing role: {role_arn}")
        return role_arn
    except iam_client.exceptions.NoSuchEntityException:
        print("   Role not found, creating new role...")
        
        # Trust policy for Lambda
        trust_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"Service": "lambda.amazonaws.com"},
                    "Action": "sts:AssumeRole"
                }
            ]
        }
        
        # Create role
        response = iam_client.create_role(
            RoleName=LAMBDA_ROLE_NAME,
            AssumeRolePolicyDocument=json.dumps(trust_policy),
            Description="Role for Blog Generator Lambda function"
        )
        role_arn = response['Role']['Arn']
        
        # Attach policies
        print("   Attaching policies...")
        iam_client.attach_role_policy(
            RoleName=LAMBDA_ROLE_NAME,
            PolicyArn="arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        )
        
        # Create inline policy for Bedrock and S3
        inline_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "bedrock:InvokeModel"
                    ],
                    "Resource": "*"
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "s3:PutObject",
                        "s3:PutObjectAcl"
                    ],
                    "Resource": f"arn:aws:s3:::{S3_BUCKET_NAME}/*"
                }
            ]
        }
        
        iam_client.put_role_policy(
            RoleName=LAMBDA_ROLE_NAME,
            PolicyName="BedrockS3Access",
            PolicyDocument=json.dumps(inline_policy)
        )
        
        print(f"✅ Role created: {role_arn}")
        print("   Waiting for role to propagate...")
        time.sleep(10)
        
        return role_arn

def deploy_lambda(zip_file, role_arn):
    """Deploy or update the Lambda function"""
    print(f"\n🚀 Deploying Lambda function: {LAMBDA_FUNCTION_NAME}...")
    
    lambda_client = boto3.client('lambda', region_name=REGION)
    
    with open(zip_file, 'rb') as f:
        zip_content = f.read()
    
    try:
        # Try to update existing function
        response = lambda_client.update_function_code(
            FunctionName=LAMBDA_FUNCTION_NAME,
            ZipFile=zip_content
        )
        print(f"✅ Function updated: {response['FunctionArn']}")
        
        # Update configuration
        lambda_client.update_function_configuration(
            FunctionName=LAMBDA_FUNCTION_NAME,
            Runtime=RUNTIME,
            Handler=HANDLER,
            Timeout=TIMEOUT,
            MemorySize=MEMORY_SIZE
        )
        
    except lambda_client.exceptions.ResourceNotFoundException:
        # Create new function
        print("   Function not found, creating new function...")
        response = lambda_client.create_function(
            FunctionName=LAMBDA_FUNCTION_NAME,
            Runtime=RUNTIME,
            Role=role_arn,
            Handler=HANDLER,
            Code={'ZipFile': zip_content},
            Description='AI Blog Generator using Amazon Bedrock',
            Timeout=TIMEOUT,
            MemorySize=MEMORY_SIZE,
            Environment={
                'Variables': {
                    'S3_BUCKET': S3_BUCKET_NAME
                }
            }
        )
        print(f"✅ Function created: {response['FunctionArn']}")
    
    return response['FunctionArn']

def test_lambda_function():
    """Test the deployed Lambda function"""
    print("\n🧪 Testing Lambda function...")
    
    lambda_client = boto3.client('lambda', region_name=REGION)
    
    test_event = {
        "body": json.dumps({
            "blog_topic": "The Future of Artificial Intelligence",
            "word_count": 150,
            "output_format": "text"
        })
    }
    
    try:
        response = lambda_client.invoke(
            FunctionName=LAMBDA_FUNCTION_NAME,
            InvocationType='RequestResponse',
            Payload=json.dumps(test_event)
        )
        
        result = json.loads(response['Payload'].read())
        print(f"✅ Test completed!")
        print(f"   Status Code: {result.get('statusCode')}")
        print(f"   Response: {result.get('body')}")
        
    except Exception as e:
        print(f"❌ Test failed: {e}")

def main():
    """Main deployment workflow"""
    print("=" * 70)
    print("🚀 AWS Lambda Deployment - Blog Generator")
    print("=" * 70)
    
    try:
        # Create deployment package
        zip_file = create_deployment_package()
        
        # Initialize AWS clients
        iam_client = boto3.client('iam', region_name=REGION)
        
        # Get or create IAM role
        role_arn = get_or_create_role(iam_client)
        
        # Deploy Lambda function
        function_arn = deploy_lambda(zip_file, role_arn)
        
        # Test the function
        test_lambda_function()
        
        print("\n" + "=" * 70)
        print("✅ Deployment completed successfully!")
        print("=" * 70)
        print(f"\n📝 Function Name: {LAMBDA_FUNCTION_NAME}")
        print(f"🌍 Region: {REGION}")
        print(f"🔗 ARN: {function_arn}")
        print(f"\n💡 You can now invoke the function via AWS Console, CLI, or API Gateway")
        
    except Exception as e:
        print(f"\n❌ Deployment failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
