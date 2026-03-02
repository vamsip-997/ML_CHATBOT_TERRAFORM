"""
Production-ready AWS Lambda function for AI Assistant
Optimized for AWS Lambda environment with proper error handling and logging
"""

import json
import logging
import os
from datetime import datetime
import boto3
import botocore.config

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
BEDROCK_REGION = os.environ.get('BEDROCK_REGION', 'us-east-1')
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'us.anthropic.claude-3-haiku-20240307-v1:0')
S3_BUCKET = os.environ.get('S3_BUCKET', '')
MAX_TOKENS_LIMIT = int(os.environ.get('MAX_TOKENS_LIMIT', '4096'))

# Initialize Bedrock client (reused across invocations)
bedrock_client = None

def get_bedrock_client():
    """Get or create Bedrock client (singleton pattern for Lambda)"""
    global bedrock_client
    if bedrock_client is None:
        bedrock_client = boto3.client(
            "bedrock-runtime",
            region_name=BEDROCK_REGION,
            config=botocore.config.Config(
                read_timeout=300,
                retries={'max_attempts': 3, 'mode': 'adaptive'}
            )
        )
    return bedrock_client

def ai_generate_response(user_input: str, response_type: str = "general", 
                         max_tokens: int = 1024, output_format: str = "text") -> dict:
    """
    Generate an AI response using Amazon Bedrock's Claude model.
    
    Returns:
        dict: {'success': bool, 'response': str, 'error': str}
    """
    try:
        # Validate and sanitize inputs
        if not user_input or not user_input.strip():
            return {'success': False, 'error': 'user_input cannot be empty'}
        
        user_input = user_input.strip()[:10000]  # Limit input length
        max_tokens = min(max_tokens, MAX_TOKENS_LIMIT)  # Enforce token limit
        
        # Build the prompt based on response type and output format
        format_instructions = {
            "text": "Respond in plain text format.",
            "html": "Respond in HTML format with proper tags like <h1>, <h2>, <p>, etc.",
            "markdown": "Respond in Markdown format with proper headers (#, ##), bold (**text**), and formatting."
        }
        
        response_type_prompts = {
            "general": f"{user_input}",
            "blog": f"Write a blog post about: {user_input}",
            "explain": f"Explain the following topic in detail: {user_input}",
            "summarize": f"Provide a summary of: {user_input}",
            "code": f"Help with this code/programming question: {user_input}"
        }
        
        format_instruction = format_instructions.get(output_format, format_instructions["text"])
        base_prompt = response_type_prompts.get(response_type, user_input)
        prompt = f"{base_prompt}\n\n{format_instruction}"
        
        # Claude API request body
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": max_tokens,
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.7
        }
        
        logger.info(f"Invoking Bedrock model: {BEDROCK_MODEL_ID}")
        
        # Call Bedrock
        bedrock = get_bedrock_client()
        response = bedrock.invoke_model(
            body=json.dumps(body),
            modelId=BEDROCK_MODEL_ID
        )
        
        # Parse response
        response_content = response.get('body').read()
        response_data = json.loads(response_content)
        
        ai_response = response_data['content'][0]['text']
        
        logger.info(f"Successfully generated response, length: {len(ai_response)}")
        
        return {
            'success': True,
            'response': ai_response,
            'metadata': {
                'model': BEDROCK_MODEL_ID,
                'tokens_used': response_data.get('usage', {})
            }
        }
        
    except botocore.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        logger.error(f"Bedrock ClientError: {error_code} - {error_message}")
        
        return {
            'success': False,
            'error': f"Bedrock error: {error_code}",
            'error_detail': error_message
        }
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return {
            'success': False,
            'error': 'Internal server error',
            'error_detail': str(e)
        }

def save_to_s3(content: str, metadata: dict) -> dict:
    """Save response to S3 bucket"""
    if not S3_BUCKET:
        return {'success': False, 'error': 'S3_BUCKET not configured'}
    
    try:
        s3 = boto3.client('s3')
        current_time = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Determine file extension and content type
        output_format = metadata.get('format', 'text')
        extensions = {'text': 'txt', 'html': 'html', 'markdown': 'md'}
        content_types = {
            'text': 'text/plain',
            'html': 'text/html',
            'markdown': 'text/markdown'
        }
        
        file_ext = extensions.get(output_format, 'txt')
        content_type = content_types.get(output_format, 'text/plain')
        
        s3_key = f"ai-output/{current_time}.{file_ext}"
        
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=content,
            ContentType=content_type,
            Metadata={
                'response_type': metadata.get('response_type', 'unknown'),
                'timestamp': current_time
            }
        )
        
        logger.info(f"Saved to S3: s3://{S3_BUCKET}/{s3_key}")
        
        return {
            'success': True,
            's3_location': f"s3://{S3_BUCKET}/{s3_key}",
            's3_key': s3_key
        }
        
    except Exception as e:
        logger.error(f"S3 save error: {str(e)}")
        return {
            'success': False,
            'error': f"Failed to save to S3: {str(e)}"
        }

def lambda_handler(event, context):
    """
    Production-ready Lambda handler with proper error handling and validation.
    
    Supports both API Gateway and direct invocation.
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse input (supports both API Gateway and direct invocation)
        if 'body' in event:
            # API Gateway format
            if isinstance(event['body'], str):
                body = json.loads(event['body'])
            else:
                body = event['body']
        else:
            # Direct invocation
            body = event
        
        # Extract and validate parameters
        user_input = body.get('user_input') or body.get('blog_topic')
        response_type = body.get('response_type', 'general')
        word_count = body.get('word_count', 200)
        output_format = body.get('output_format', 'text')
        save_s3 = body.get('save_to_s3', False)
        
        # Backward compatibility: if blog_topic provided, treat as blog
        if body.get('blog_topic') and not body.get('user_input'):
            response_type = 'blog'
        
        # Validate required parameters
        if not user_input:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'user_input or blog_topic is required'
                })
            }
        
        # Validate and sanitize inputs
        word_count = max(50, min(word_count, 2000))
        
        if output_format not in ['text', 'html', 'markdown']:
            output_format = 'text'
        
        if response_type not in ['general', 'blog', 'explain', 'summarize', 'code']:
            response_type = 'general'
        
        # Calculate max tokens
        if response_type == 'blog':
            max_tokens = max(512, word_count * 2)
        else:
            max_tokens = 2048
        
        # Generate AI response
        result = ai_generate_response(
            user_input=user_input,
            response_type=response_type,
            max_tokens=max_tokens,
            output_format=output_format
        )
        
        if not result['success']:
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps(result)
            }
        
        # Prepare response
        response_body = {
            'success': True,
            'response': result['response'],
            'metadata': {
                'input': user_input,
                'response_type': response_type,
                'output_format': output_format,
                'timestamp': datetime.now().isoformat()
            }
        }
        
        # Save to S3 if requested
        if save_s3 and S3_BUCKET:
            s3_result = save_to_s3(result['response'], {
                'format': output_format,
                'response_type': response_type
            })
            if s3_result['success']:
                response_body['s3_location'] = s3_result['s3_location']
        
        # Add usage metrics from Bedrock
        if 'metadata' in result:
            response_body['usage'] = result['metadata']
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST, OPTIONS'
            },
            'body': json.dumps(response_body)
        }
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Invalid JSON in request body'
            })
        }
        
    except Exception as e:
        logger.error(f"Unexpected error in lambda_handler: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Internal server error',
                'error_detail': str(e) if os.environ.get('DEBUG') else None
            })
        }
