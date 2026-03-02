import boto3
import botocore.config
import json

from datetime import datetime

def ai_generate_response(user_input: str, response_type: str = "general", max_tokens: int = 1024, output_format: str = "text") -> str:
    """
    Generate an AI response using Amazon Bedrock's Claude model for ANY topic.
    
    Args:
        user_input: The user's question, topic, or prompt
        response_type: Type of response - 'general', 'blog', 'explain', 'summarize', 'code' (default: 'general')
        max_tokens: Maximum tokens for response (default: 1024)
        output_format: Output format - 'text', 'html', or 'markdown' (default: 'text')
    
    Returns:
        Generated AI response in the specified format
    """
    
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
    
    # Claude format
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

    try:
        bedrock = boto3.client("bedrock-runtime", region_name="us-east-1",
                              config=botocore.config.Config(read_timeout=300, retries={'max_attempts': 3}))
        response = bedrock.invoke_model(body=json.dumps(body), modelId="us.anthropic.claude-3-haiku-20240307-v1:0")

        response_content = response.get('body').read()
        response_data = json.loads(response_content)
        print(response_data)
        ai_response = response_data['content'][0]['text']
        return ai_response
    except Exception as e:
        print(f"Error generating AI response: {e}")
        return ""

def blog_generate_using_bedrock(blogtopic: str, word_count: int = 200, output_format: str = "text") -> str:
    """
    Generate a blog post using Amazon Bedrock's Claude model.
    (Wrapper for backward compatibility)
    
    Args:
        blogtopic: The topic for the blog post
        word_count: Desired word count (default: 200)
        output_format: Output format - 'text', 'html', or 'markdown' (default: 'text')
    
    Returns:
        Generated blog content in the specified format
    """
    prompt = f"Write a {word_count} words blog post on the topic: {blogtopic}."
    max_tokens = max(512, word_count * 2)
    return ai_generate_response(prompt, response_type="blog", max_tokens=max_tokens, output_format=output_format)

def save_blog_details_s3(s3_key, s3_bucket, generate_blog, content_type="text/plain"):
    """
    Save generated blog to S3 bucket.
    
    Args:
        s3_key: S3 object key (path)
        s3_bucket: S3 bucket name
        generate_blog: Blog content to save
        content_type: MIME type for the content (default: text/plain)
    """
    s3 = boto3.client('s3')

    try:
        s3.put_object(
            Bucket=s3_bucket, 
            Key=s3_key, 
            Body=generate_blog,
            ContentType=content_type
        )
        print(f"Blog saved to S3: s3://{s3_bucket}/{s3_key}")
        return True

    except Exception as e:
        print(f"Error when saving the blog to S3: {e}")
        return False


def lambda_handler(event, context):
    """
    AWS Lambda handler for AI response generation.
    
    Expected event format:
    {
        "body": "{
            \"user_input\": \"your question or topic here\",
            \"response_type\": \"general\",
            \"word_count\": 200,
            \"output_format\": \"text\"
        }"
    }
    
    Legacy format (backward compatible):
    {
        "body": "{
            \"blog_topic\": \"topic here\",
            \"word_count\": 200,
            \"output_format\": \"text\"
        }"
    }
    """
    try:
        # Parse the event
        event_body = json.loads(event['body']) if isinstance(event.get('body'), str) else event.get('body', {})
        
        # Support both new and legacy formats
        user_input = event_body.get('user_input') or event_body.get('blog_topic')
        response_type = event_body.get('response_type', 'general')
        word_count = event_body.get('word_count', 200)
        output_format = event_body.get('output_format', 'text')
        
        # If blog_topic was provided, treat it as a blog request
        if event_body.get('blog_topic') and not event_body.get('user_input'):
            response_type = 'blog'
        
        if not user_input:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'user_input or blog_topic is required'})
            }
        
        # Validate word count
        word_count = max(50, min(word_count, 2000))  # Between 50 and 2000 words
        
        # Validate format
        if output_format not in ['text', 'html', 'markdown']:
            output_format = 'text'
        
        # Validate response type
        if response_type not in ['general', 'blog', 'explain', 'summarize', 'code']:
            response_type = 'general'
        
        # Calculate max tokens based on response type
        if response_type == 'blog':
            max_tokens = max(512, word_count * 2)
        else:
            max_tokens = 2048

        # Generate AI response
        ai_response = ai_generate_response(
            user_input=user_input,
            response_type=response_type,
            max_tokens=max_tokens,
            output_format=output_format
        )

        if ai_response:
            current_time = datetime.now().strftime('%Y%m%d_%H%M%S')
            
            # Determine file extension and content type
            extensions = {'text': 'txt', 'html': 'html', 'markdown': 'md'}
            content_types = {
                'text': 'text/plain',
                'html': 'text/html',
                'markdown': 'text/markdown'
            }
            
            file_ext = extensions.get(output_format, 'txt')
            content_type = content_types.get(output_format, 'text/plain')
            
            s3_key = f"ai-output/{current_time}.{file_ext}"
            s3_bucket = 'blog-generator-storage-rishi-2026'
            
            save_blog_details_s3(s3_key, s3_bucket, ai_response, content_type)

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'AI response generated successfully',
                    'response': ai_response,
                    'input': user_input,
                    'response_type': response_type,
                    'word_count': word_count,
                    'format': output_format,
                    's3_location': f"s3://{s3_bucket}/{s3_key}"
                })
            }
        else:
            return {
                'statusCode': 500,
                'body': json.dumps({'error': 'Failed to generate AI response'})
            }
            
    except Exception as e:
        print(f"Error in lambda_handler: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
