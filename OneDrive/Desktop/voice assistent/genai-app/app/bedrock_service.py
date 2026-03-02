"""
Bedrock Service - Handles interactions with AWS Bedrock Knowledge Base
"""
import os
import json
import boto3
from typing import Dict, List, Optional
import logging

logger = logging.getLogger(__name__)


class BedrockService:
    """Service for interacting with AWS Bedrock Knowledge Base"""
    
    def __init__(self):
        self.region = os.getenv("AWS_REGION", "us-east-1")
        self.knowledge_base_id = os.getenv("BEDROCK_KB_ID")
        self.model_id = os.getenv("BEDROCK_MODEL_ID", "anthropic.claude-3-sonnet-20240229-v1:0")
        
        # Initialize Bedrock clients
        self.bedrock_agent_runtime = boto3.client(
            'bedrock-agent-runtime',
            region_name=self.region
        )
        self.bedrock_runtime = boto3.client(
            'bedrock-runtime',
            region_name=self.region
        )
        
    def retrieve_from_kb(self, query: str, max_results: int = 5) -> List[Dict]:
        """
        Retrieve relevant documents from Bedrock Knowledge Base
        
        Args:
            query: User query
            max_results: Maximum number of results to return
            
        Returns:
            List of retrieved documents with content and metadata
        """
        try:
            response = self.bedrock_agent_runtime.retrieve(
                knowledgeBaseId=self.knowledge_base_id,
                retrievalQuery={'text': query},
                retrievalConfiguration={
                    'vectorSearchConfiguration': {
                        'numberOfResults': max_results
                    }
                }
            )
            
            results = []
            for item in response.get('retrievalResults', []):
                results.append({
                    'content': item['content']['text'],
                    'score': item.get('score', 0),
                    'metadata': item.get('metadata', {}),
                    'location': item.get('location', {})
                })
            
            return results
            
        except Exception as e:
            logger.error(f"Error retrieving from knowledge base: {str(e)}")
            raise
    
    def retrieve_and_generate(self, query: str, session_id: Optional[str] = None) -> Dict:
        """
        Retrieve from KB and generate response using Bedrock
        
        Args:
            query: User query
            session_id: Optional session ID for conversation continuity
            
        Returns:
            Dictionary with generated response and citations
        """
        try:
            request_params = {
                'input': {'text': query},
                'retrieveAndGenerateConfiguration': {
                    'type': 'KNOWLEDGE_BASE',
                    'knowledgeBaseConfiguration': {
                        'knowledgeBaseId': self.knowledge_base_id,
                        'modelArn': f'arn:aws:bedrock:{self.region}::foundation-model/{self.model_id}'
                    }
                }
            }
            
            if session_id:
                request_params['sessionId'] = session_id
            
            response = self.bedrock_agent_runtime.retrieve_and_generate(**request_params)
            
            return {
                'response': response['output']['text'],
                'citations': response.get('citations', []),
                'session_id': response.get('sessionId')
            }
            
        except Exception as e:
            logger.error(f"Error in retrieve and generate: {str(e)}")
            raise
    
    def invoke_model(self, prompt: str, context: Optional[str] = None) -> str:
        """
        Invoke Bedrock model directly with a prompt
        
        Args:
            prompt: User prompt
            context: Optional context from knowledge base
            
        Returns:
            Generated response text
        """
        try:
            if context:
                full_prompt = f"Context:\n{context}\n\nQuestion: {prompt}\n\nAnswer:"
            else:
                full_prompt = prompt
            
            # Format for Claude models
            body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 2048,
                "messages": [
                    {
                        "role": "user",
                        "content": full_prompt
                    }
                ],
                "temperature": 0.7,
                "top_p": 0.9
            }
            
            response = self.bedrock_runtime.invoke_model(
                modelId=self.model_id,
                body=json.dumps(body)
            )
            
            response_body = json.loads(response['body'].read())
            return response_body['content'][0]['text']
            
        except Exception as e:
            logger.error(f"Error invoking model: {str(e)}")
            raise
