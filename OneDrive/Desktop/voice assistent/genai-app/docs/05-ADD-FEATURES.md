# Add Advanced Features

This guide shows you how to add advanced features to enhance your GenAI Chatbot.

## Table of Contents

1. [Streaming Responses](#streaming-responses)
2. [Conversation Memory](#conversation-memory)
3. [Analytics & Monitoring](#analytics--monitoring)
4. [Multi-Modal Support](#multi-modal-support)
5. [Advanced RAG Features](#advanced-rag-features)
6. [WebSocket Support](#websocket-support)

## Streaming Responses

### Implementation

Add streaming support to `app/bedrock_service.py`:

```python
from typing import Iterator
import json

class BedrockService:
    def invoke_model_stream(self, prompt: str, context: Optional[str] = None) -> Iterator[str]:
        """
        Invoke Bedrock model with streaming response
        
        Args:
            prompt: User prompt
            context: Optional context from knowledge base
            
        Yields:
            Response chunks as they're generated
        """
        try:
            if context:
                full_prompt = f"Context:\n{context}\n\nQuestion: {prompt}\n\nAnswer:"
            else:
                full_prompt = prompt
            
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
            }
            
            response = self.bedrock_runtime.invoke_model_with_response_stream(
                modelId=self.model_id,
                body=json.dumps(body)
            )
            
            # Process the stream
            for event in response['body']:
                chunk = json.loads(event['chunk']['bytes'])
                
                if chunk['type'] == 'content_block_delta':
                    if 'delta' in chunk and 'text' in chunk['delta']:
                        yield chunk['delta']['text']
                elif chunk['type'] == 'message_stop':
                    break
                    
        except Exception as e:
            logger.error(f"Error in streaming: {str(e)}")
            raise
```

### Update Routes

Add streaming endpoint in `app/routes.py`:

```python
from fastapi.responses import StreamingResponse
from typing import AsyncIterator

async def generate_stream(query: str, use_kb: bool) -> AsyncIterator[str]:
    """Generate streaming response"""
    try:
        if use_kb:
            # Retrieve context first
            results = bedrock_service.retrieve_from_kb(query, max_results=3)
            context = "\n\n".join([r['content'] for r in results])
        else:
            context = None
        
        # Stream the response
        for chunk in bedrock_service.invoke_model_stream(query, context):
            yield f"data: {json.dumps({'text': chunk})}\n\n"
        
        yield "data: [DONE]\n\n"
        
    except Exception as e:
        yield f"data: {json.dumps({'error': str(e)})}\n\n"

@router.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    """
    Streaming chat endpoint
    
    Returns Server-Sent Events (SSE) stream
    """
    return StreamingResponse(
        generate_stream(request.query, request.use_kb),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        }
    )
```

### Client-Side Usage

```javascript
// JavaScript client
const eventSource = new EventSource('/api/v1/chat/stream', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    query: 'What is your product?',
    use_kb: true
  })
});

let fullResponse = '';

eventSource.onmessage = (event) => {
  if (event.data === '[DONE]') {
    eventSource.close();
    console.log('Stream completed');
    return;
  }
  
  const data = JSON.parse(event.data);
  fullResponse += data.text;
  console.log(fullResponse);
};

eventSource.onerror = (error) => {
  console.error('Stream error:', error);
  eventSource.close();
};
```

## Conversation Memory

### DynamoDB Setup

Add to `terraform/dynamodb.tf`:

```hcl
resource "aws_dynamodb_table" "conversations" {
  name           = "${var.project_name}-conversations-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"
  range_key      = "timestamp"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  global_secondary_index {
    name            = "UserIdIndex"
    hash_key        = "user_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "${var.project_name}-conversations"
    Environment = var.environment
  }
}
```

### Memory Service

Create `app/memory_service.py`:

```python
import boto3
from typing import List, Dict
from datetime import datetime, timedelta
import uuid

class ConversationMemory:
    """Service for managing conversation history"""
    
    def __init__(self):
        self.dynamodb = boto3.resource('dynamodb')
        self.table_name = os.getenv('CONVERSATIONS_TABLE')
        self.table = self.dynamodb.Table(self.table_name)
        self.max_history = 10  # Keep last 10 messages
    
    def save_message(self, session_id: str, role: str, content: str, user_id: str = None):
        """Save a message to conversation history"""
        timestamp = int(datetime.utcnow().timestamp() * 1000)
        ttl = int((datetime.utcnow() + timedelta(days=7)).timestamp())
        
        item = {
            'session_id': session_id,
            'timestamp': timestamp,
            'role': role,  # 'user' or 'assistant'
            'content': content,
            'ttl': ttl
        }
        
        if user_id:
            item['user_id'] = user_id
        
        self.table.put_item(Item=item)
    
    def get_conversation_history(self, session_id: str, limit: int = None) -> List[Dict]:
        """Retrieve conversation history"""
        response = self.table.query(
            KeyConditionExpression='session_id = :sid',
            ExpressionAttributeValues={':sid': session_id},
            ScanIndexForward=True,  # Oldest first
            Limit=limit or self.max_history
        )
        
        return response.get('Items', [])
    
    def format_history_for_prompt(self, session_id: str) -> str:
        """Format conversation history for inclusion in prompt"""
        history = self.get_conversation_history(session_id)
        
        formatted = []
        for msg in history:
            role = "Human" if msg['role'] == 'user' else "Assistant"
            formatted.append(f"{role}: {msg['content']}")
        
        return "\n".join(formatted)
    
    def clear_conversation(self, session_id: str):
        """Clear conversation history"""
        history = self.get_conversation_history(session_id, limit=1000)
        
        with self.table.batch_writer() as batch:
            for item in history:
                batch.delete_item(
                    Key={
                        'session_id': item['session_id'],
                        'timestamp': item['timestamp']
                    }
                )
```

### Update Routes with Memory

```python
from .memory_service import ConversationMemory

memory_service = ConversationMemory()

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Chat with conversation memory"""
    try:
        # Generate session ID if not provided
        session_id = request.session_id or str(uuid.uuid4())
        
        # Get conversation history
        history = memory_service.format_history_for_prompt(session_id)
        
        # Save user message
        memory_service.save_message(session_id, 'user', request.query)
        
        # Build prompt with history
        if history:
            enhanced_query = f"Previous conversation:\n{history}\n\nCurrent question: {request.query}"
        else:
            enhanced_query = request.query
        
        # Get response
        result = bedrock_service.retrieve_and_generate(
            query=enhanced_query,
            session_id=session_id
        )
        
        # Save assistant response
        memory_service.save_message(session_id, 'assistant', result['response'])
        
        return ChatResponse(
            response=result['response'],
            session_id=session_id,
            citations=result.get('citations', [])
        )
        
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/chat/history/{session_id}")
async def clear_history(session_id: str):
    """Clear conversation history"""
    try:
        memory_service.clear_conversation(session_id)
        return {"message": "Conversation history cleared"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

## Analytics & Monitoring

### CloudWatch Custom Metrics

Create `app/metrics.py`:

```python
import boto3
from datetime import datetime

class MetricsService:
    """Service for publishing custom metrics"""
    
    def __init__(self):
        self.cloudwatch = boto3.client('cloudwatch')
        self.namespace = 'GenAI-Chatbot'
    
    def record_chat_request(self, model: str, tokens: int, latency_ms: int):
        """Record chat request metrics"""
        self.cloudwatch.put_metric_data(
            Namespace=self.namespace,
            MetricData=[
                {
                    'MetricName': 'ChatRequests',
                    'Value': 1,
                    'Unit': 'Count',
                    'Timestamp': datetime.utcnow(),
                    'Dimensions': [
                        {'Name': 'Model', 'Value': model}
                    ]
                },
                {
                    'MetricName': 'TokensUsed',
                    'Value': tokens,
                    'Unit': 'Count',
                    'Timestamp': datetime.utcnow(),
                    'Dimensions': [
                        {'Name': 'Model', 'Value': model}
                    ]
                },
                {
                    'MetricName': 'ResponseLatency',
                    'Value': latency_ms,
                    'Unit': 'Milliseconds',
                    'Timestamp': datetime.utcnow(),
                    'Dimensions': [
                        {'Name': 'Model', 'Value': model}
                    ]
                }
            ]
        )
    
    def record_error(self, error_type: str):
        """Record error metrics"""
        self.cloudwatch.put_metric_data(
            Namespace=self.namespace,
            MetricData=[
                {
                    'MetricName': 'Errors',
                    'Value': 1,
                    'Unit': 'Count',
                    'Timestamp': datetime.utcnow(),
                    'Dimensions': [
                        {'Name': 'ErrorType', 'Value': error_type}
                    ]
                }
            ]
        )
```

### Usage Tracking

Create `app/usage_tracking.py`:

```python
import boto3
from decimal import Decimal

class UsageTracker:
    """Track API usage per user/organization"""
    
    def __init__(self):
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(os.getenv('USAGE_TABLE'))
    
    def record_usage(self, user_id: str, tokens: int, cost: float):
        """Record usage for billing"""
        today = datetime.utcnow().strftime('%Y-%m-%d')
        
        self.table.update_item(
            Key={'user_id': user_id, 'date': today},
            UpdateExpression='ADD tokens :tokens, cost :cost, requests :req',
            ExpressionAttributeValues={
                ':tokens': tokens,
                ':cost': Decimal(str(cost)),
                ':req': 1
            }
        )
    
    def get_usage(self, user_id: str, start_date: str, end_date: str):
        """Get usage statistics"""
        response = self.table.query(
            KeyConditionExpression='user_id = :uid AND #date BETWEEN :start AND :end',
            ExpressionAttributeNames={'#date': 'date'},
            ExpressionAttributeValues={
                ':uid': user_id,
                ':start': start_date,
                ':end': end_date
            }
        )
        
        return response.get('Items', [])
```

### Request Tracking Middleware

Add to `app/main.py`:

```python
import time
from .metrics import MetricsService

metrics_service = MetricsService()

@app.middleware("http")
async def track_requests(request: Request, call_next):
    start_time = time.time()
    
    try:
        response = await call_next(request)
        
        # Record successful request
        latency = int((time.time() - start_time) * 1000)
        
        if request.url.path.startswith('/api/v1/chat'):
            metrics_service.record_chat_request(
                model=os.getenv('BEDROCK_MODEL_ID', 'unknown'),
                tokens=0,  # Update with actual tokens
                latency_ms=latency
            )
        
        return response
        
    except Exception as e:
        # Record error
        metrics_service.record_error(type(e).__name__)
        raise
```

## Multi-Modal Support

### Image Analysis

Add image analysis capability:

```python
class BedrockService:
    def analyze_image(self, image_bytes: bytes, prompt: str) -> str:
        """
        Analyze an image using Claude's vision capabilities
        
        Args:
            image_bytes: Image data in bytes
            prompt: Question about the image
            
        Returns:
            Analysis result
        """
        import base64
        
        image_b64 = base64.b64encode(image_bytes).decode('utf-8')
        
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 2048,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": image_b64
                            }
                        },
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ]
                }
            ]
        }
        
        response = self.bedrock_runtime.invoke_model(
            modelId='anthropic.claude-3-sonnet-20240229-v1:0',
            body=json.dumps(body)
        )
        
        response_body = json.loads(response['body'].read())
        return response_body['content'][0]['text']
```

### Add Image Upload Route

```python
@router.post("/analyze-image")
async def analyze_image(
    file: UploadFile = File(...),
    prompt: str = "Describe this image in detail"
):
    """Analyze an uploaded image"""
    try:
        # Read image
        image_bytes = await file.read()
        
        # Analyze with Bedrock
        result = bedrock_service.analyze_image(image_bytes, prompt)
        
        return {"analysis": result}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

## Advanced RAG Features

### Re-ranking Results

Add result re-ranking for better relevance:

```python
class BedrockService:
    def rerank_results(self, query: str, results: List[Dict]) -> List[Dict]:
        """
        Re-rank retrieved results using a cross-encoder
        
        Args:
            query: User query
            results: Retrieved documents
            
        Returns:
            Re-ranked results
        """
        # Use Bedrock to score each result
        scored_results = []
        
        for result in results:
            prompt = f"""On a scale of 0-100, how relevant is this document to the query?

Query: {query}

Document: {result['content'][:500]}

Relevance score (just the number):"""
            
            try:
                score_text = self.invoke_model(prompt)
                score = float(score_text.strip())
                result['rerank_score'] = score
                scored_results.append(result)
            except:
                result['rerank_score'] = result.get('score', 0)
                scored_results.append(result)
        
        # Sort by rerank score
        return sorted(scored_results, key=lambda x: x['rerank_score'], reverse=True)
```

### Hybrid Search

Combine vector search with keyword search:

```python
def hybrid_search(self, query: str, max_results: int = 5) -> List[Dict]:
    """
    Perform hybrid search combining semantic and keyword search
    """
    # Get vector search results
    vector_results = self.retrieve_from_kb(query, max_results)
    
    # Perform keyword search on S3 documents (simplified example)
    # In production, use OpenSearch or Elasticsearch
    
    # Combine and deduplicate results
    combined = vector_results  # Implement proper merging logic
    
    # Re-rank combined results
    reranked = self.rerank_results(query, combined)
    
    return reranked[:max_results]
```

### Query Expansion

Expand queries for better retrieval:

```python
def expand_query(self, query: str) -> List[str]:
    """Generate related queries for better coverage"""
    prompt = f"""Generate 3 alternative phrasings of this query that might help find relevant information:

Original query: {query}

Alternative queries (one per line):"""
    
    response = self.invoke_model(prompt)
    alternatives = [q.strip() for q in response.split('\n') if q.strip()]
    
    return [query] + alternatives[:3]
```

## WebSocket Support

### Add WebSocket Endpoint

Create `app/websocket.py`:

```python
from fastapi import WebSocket, WebSocketDisconnect
from typing import List
import json

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
    
    async def send_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)
    
    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

@app.websocket("/ws/chat")
async def websocket_chat(websocket: WebSocket):
    await manager.connect(websocket)
    
    try:
        while True:
            # Receive message
            data = await websocket.receive_text()
            request = json.loads(data)
            
            query = request.get('query')
            session_id = request.get('session_id')
            
            # Process with streaming
            for chunk in bedrock_service.invoke_model_stream(query):
                await manager.send_message(
                    json.dumps({'type': 'chunk', 'data': chunk}),
                    websocket
                )
            
            # Send completion
            await manager.send_message(
                json.dumps({'type': 'done'}),
                websocket
            )
            
    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

## Next Steps

After implementing these features:

1. **Test thoroughly** - Each feature needs comprehensive testing
2. **Monitor performance** - Track metrics and optimize
3. **Gather feedback** - Get user input on new features
4. **Iterate** - Continuously improve based on usage

## Related Documentation

- 🚀 [Deploy infrastructure](./01-DEPLOY-INFRASTRUCTURE.md)
- 🧪 [Test locally](./02-TEST-LOCALLY.md)
- ⚙️ [Customize config](./03-CUSTOMIZE-CONFIG.md)
- 📦 [Set up CI/CD](./04-SETUP-GITHUB-ACTIONS.md)
- 📋 [Code review guide](./06-CODE-REVIEW.md)
