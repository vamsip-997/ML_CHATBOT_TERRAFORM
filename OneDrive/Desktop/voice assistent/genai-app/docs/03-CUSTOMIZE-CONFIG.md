# Customize Configuration

This guide shows you how to customize and extend the GenAI Chatbot configuration.

## Table of Contents

1. [Bedrock Model Configuration](#bedrock-model-configuration)
2. [Knowledge Base Settings](#knowledge-base-settings)
3. [API Configuration](#api-configuration)
4. [Security Settings](#security-settings)
5. [Performance Tuning](#performance-tuning)
6. [Environment-Specific Config](#environment-specific-config)

## Bedrock Model Configuration

### Change Foundation Model

Edit `app/bedrock_service.py` to use different models:

```python
class BedrockService:
    def __init__(self):
        # Available models:
        # - anthropic.claude-3-opus-20240229-v1:0 (Most capable)
        # - anthropic.claude-3-sonnet-20240229-v1:0 (Balanced)
        # - anthropic.claude-3-haiku-20240307-v1:0 (Fastest, cheapest)
        # - amazon.titan-text-premier-v1:0
        # - meta.llama3-70b-instruct-v1:0
        
        self.model_id = os.getenv(
            "BEDROCK_MODEL_ID", 
            "anthropic.claude-3-haiku-20240307-v1:0"  # Change here
        )
```

Or set in `.env`:
```bash
BEDROCK_MODEL_ID=anthropic.claude-3-opus-20240229-v1:0
```

### Adjust Model Parameters

Modify generation parameters in `bedrock_service.py`:

```python
def invoke_model(self, prompt: str, context: Optional[str] = None) -> str:
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4096,        # Increase for longer responses
        "messages": [
            {
                "role": "user",
                "content": full_prompt
            }
        ],
        "temperature": 0.5,        # Lower = more focused, Higher = more creative
        "top_p": 0.9,             # Nucleus sampling
        "top_k": 250,             # Top-K sampling
        "stop_sequences": ["\n\nHuman:"]  # Stop generation at these sequences
    }
```

### Configure Embedding Model

For Knowledge Base, change the embedding model in `terraform/bedrock.tf`:

```hcl
resource "aws_bedrockagent_knowledge_base" "genai_kb" {
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      # Options:
      # - amazon.titan-embed-text-v1 (1536 dimensions)
      # - amazon.titan-embed-text-v2:0 (1024 or 256 dimensions)
      # - cohere.embed-english-v3
      # - cohere.embed-multilingual-v3
      embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.titan-embed-text-v2:0"
    }
  }
}
```

## Knowledge Base Settings

### Chunking Configuration

Adjust how documents are split in `terraform/bedrock.tf`:

```hcl
resource "aws_bedrockagent_data_source" "genai_kb_s3" {
  vector_ingestion_configuration {
    chunking_configuration {
      # Options: FIXED_SIZE, HIERARCHICAL, SEMANTIC, NONE
      chunking_strategy = "FIXED_SIZE"
      
      fixed_size_chunking_configuration {
        max_tokens         = 512    # Increase for more context per chunk
        overlap_percentage = 20     # Overlap between chunks (0-99)
      }
      
      # Alternative: Hierarchical chunking
      # hierarchical_chunking_configuration {
      #   level_configurations {
      #     max_tokens = 1500
      #   }
      #   level_configurations {
      #     max_tokens = 300
      #   }
      #   overlap_tokens = 60
      # }
      
      # Alternative: Semantic chunking
      # semantic_chunking_configuration {
      #   max_tokens = 300
      #   buffer_size = 0
      #   breakpoint_percentile_threshold = 95
      # }
    }
  }
}
```

### Parsing Configuration

Add custom parsing for different file types:

```hcl
resource "aws_bedrockagent_data_source" "genai_kb_s3" {
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.bedrock_kb_source.arn
      
      # Include/exclude patterns
      inclusion_prefixes = ["documents/", "pdfs/"]
      # exclusion_patterns = ["*.tmp", "*.draft"]
    }
  }
  
  # Custom parsing
  parsing_configuration {
    parsing_strategy = "BEDROCK_FOUNDATION_MODEL"
    bedrock_foundation_model_configuration {
      model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
      parsing_prompt {
        parsing_prompt_text = "Extract and structure the key information from this document..."
      }
    }
  }
}
```

### Retrieval Configuration

Customize how documents are retrieved in `app/bedrock_service.py`:

```python
def retrieve_from_kb(self, query: str, max_results: int = 5) -> List[Dict]:
    response = self.bedrock_agent_runtime.retrieve(
        knowledgeBaseId=self.knowledge_base_id,
        retrievalQuery={'text': query},
        retrievalConfiguration={
            'vectorSearchConfiguration': {
                'numberOfResults': max_results,
                'overrideSearchType': 'HYBRID',  # HYBRID, SEMANTIC, or None
                
                # Filter by metadata
                # 'filter': {
                #     'equals': {
                #         'key': 'category',
                #         'value': 'financial'
                #     }
                # }
            }
        }
    )
```

## API Configuration

### CORS Settings

Edit `app/main.py` to configure CORS:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://yourdomain.com",
        "https://app.yourdomain.com",
        "http://localhost:3000"
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
    expose_headers=["X-Request-ID"],
    max_age=3600,
)
```

### Rate Limiting

Add rate limiting middleware:

```bash
# Install slowapi
pip install slowapi
```

Edit `app/main.py`:

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# In routes.py
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/chat")
@limiter.limit("10/minute")  # 10 requests per minute
async def chat(request: Request, chat_request: ChatRequest):
    # ... existing code
```

### Request Timeout

Configure timeouts in `app/bedrock_service.py`:

```python
from botocore.config import Config

class BedrockService:
    def __init__(self):
        config = Config(
            connect_timeout=5,
            read_timeout=60,
            retries={
                'max_attempts': 3,
                'mode': 'adaptive'
            }
        )
        
        self.bedrock_runtime = boto3.client(
            'bedrock-runtime',
            region_name=self.region,
            config=config
        )
```

### Custom Response Format

Modify response models in `app/routes.py`:

```python
class ChatResponse(BaseModel):
    response: str
    session_id: Optional[str] = None
    citations: Optional[List] = None
    metadata: Optional[Dict] = None
    tokens_used: Optional[int] = None
    response_time_ms: Optional[int] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "response": "The company's revenue increased by 15%...",
                "session_id": "session-123",
                "citations": [...],
                "metadata": {"model": "claude-3-sonnet", "confidence": 0.95},
                "tokens_used": 450,
                "response_time_ms": 1200
            }
        }
```

## Security Settings

### Authentication & Authorization

Add JWT authentication:

```bash
pip install python-jose[cryptography] passlib[bcrypt]
```

Create `app/auth.py`:

```python
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

security = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid authentication")
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid authentication")
```

Use in routes:

```python
from .auth import verify_token

@router.post("/chat")
async def chat(request: ChatRequest, user=Depends(verify_token)):
    # user is authenticated
    pass
```

### Input Validation

Add stricter validation in `app/routes.py`:

```python
from pydantic import BaseModel, Field, validator

class ChatRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=2000, description="User query")
    session_id: Optional[str] = Field(None, regex="^[a-zA-Z0-9-]+$")
    use_kb: bool = True
    
    @validator('query')
    def query_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Query cannot be empty')
        return v.strip()
    
    @validator('query')
    def sanitize_query(cls, v):
        # Remove potentially harmful characters
        dangerous_chars = ['<', '>', '{', '}', '|', '\\']
        for char in dangerous_chars:
            v = v.replace(char, '')
        return v
```

### API Key Authentication

Simple API key auth:

```python
from fastapi import Security, HTTPException
from fastapi.security import APIKeyHeader

API_KEY_HEADER = APIKeyHeader(name="X-API-Key")

async def verify_api_key(api_key: str = Security(API_KEY_HEADER)):
    if api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=403, detail="Invalid API Key")
    return api_key

# Use in routes
@router.post("/chat")
async def chat(request: ChatRequest, api_key: str = Depends(verify_api_key)):
    pass
```

## Performance Tuning

### Response Caching

Add caching for frequent queries:

```bash
pip install redis aiocache
```

Create `app/cache.py`:

```python
from aiocache import Cache
from aiocache.serializers import JsonSerializer
import hashlib

cache = Cache(Cache.REDIS, 
    endpoint=os.getenv("REDIS_HOST", "localhost"),
    port=int(os.getenv("REDIS_PORT", 6379)),
    serializer=JsonSerializer()
)

async def get_cached_response(query: str):
    cache_key = hashlib.md5(query.encode()).hexdigest()
    return await cache.get(cache_key)

async def cache_response(query: str, response: dict, ttl: int = 3600):
    cache_key = hashlib.md5(query.encode()).hexdigest()
    await cache.set(cache_key, response, ttl=ttl)
```

Use in routes:

```python
from .cache import get_cached_response, cache_response

@router.post("/chat")
async def chat(request: ChatRequest):
    # Check cache first
    cached = await get_cached_response(request.query)
    if cached:
        return cached
    
    # Generate new response
    result = bedrock_service.retrieve_and_generate(...)
    
    # Cache the result
    await cache_response(request.query, result)
    
    return result
```

### Async Processing

Use background tasks for long-running operations:

```python
from fastapi import BackgroundTasks

def process_document_async(s3_key: str, kb_id: str):
    # Long-running document processing
    pass

@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = None
):
    s3_key = s3_service.upload_file(file.file, file.filename)
    
    # Process in background
    background_tasks.add_task(
        process_document_async, 
        s3_key, 
        os.getenv("BEDROCK_KB_ID")
    )
    
    return {"message": "Upload started", "s3_key": s3_key}
```

### Connection Pooling

Configure boto3 session pooling:

```python
import boto3
from botocore.config import Config

class BedrockService:
    _session = None
    
    @classmethod
    def get_session(cls):
        if cls._session is None:
            cls._session = boto3.Session()
        return cls._session
    
    def __init__(self):
        config = Config(
            max_pool_connections=50,  # Increase connection pool
        )
        session = self.get_session()
        self.bedrock_runtime = session.client(
            'bedrock-runtime',
            config=config
        )
```

## Environment-Specific Config

### Development Settings

Create `.env.development`:

```bash
ENV=development
LOG_LEVEL=DEBUG
CORS_ORIGINS=*

# Use cheaper/faster models for dev
BEDROCK_MODEL_ID=anthropic.claude-3-haiku-20240307-v1:0

# Shorter timeouts for faster feedback
REQUEST_TIMEOUT=30

# Mock services (optional)
USE_MOCK_BEDROCK=false
```

### Production Settings

Create `.env.production`:

```bash
ENV=production
LOG_LEVEL=INFO
CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# Use production model
BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0

# Longer timeouts for production
REQUEST_TIMEOUT=60

# Enable monitoring
ENABLE_METRICS=true
ENABLE_TRACING=true
```

### Configuration Manager

Create `app/config.py`:

```python
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # AWS
    aws_region: str = "us-east-1"
    bedrock_kb_id: str
    bedrock_model_id: str = "anthropic.claude-3-sonnet-20240229-v1:0"
    s3_bucket_name: str
    
    # Application
    env: str = "production"
    port: int = 8000
    log_level: str = "INFO"
    cors_origins: str = "*"
    
    # Performance
    max_results: int = 5
    request_timeout: int = 60
    max_tokens: int = 2048
    
    # Security
    api_key: str = ""
    jwt_secret_key: str = ""
    
    class Config:
        env_file = ".env"
        case_sensitive = False

@lru_cache()
def get_settings():
    return Settings()
```

Use in application:

```python
from app.config import get_settings

settings = get_settings()

class BedrockService:
    def __init__(self):
        self.region = settings.aws_region
        self.model_id = settings.bedrock_model_id
```

## Logging Configuration

### Structured Logging

Create `app/logging_config.py`:

```python
import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
        }
        
        if hasattr(record, 'request_id'):
            log_data['request_id'] = record.request_id
        
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
        
        return json.dumps(log_data)

def setup_logging():
    handler = logging.StreamHandler()
    handler.setFormatter(JSONFormatter())
    
    root_logger = logging.getLogger()
    root_logger.addHandler(handler)
    root_logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))
```

### Request Logging Middleware

```python
import time
import uuid
from fastapi import Request

@app.middleware("http")
async def log_requests(request: Request, call_next):
    request_id = str(uuid.uuid4())
    start_time = time.time()
    
    # Add request ID to request state
    request.state.request_id = request_id
    
    # Log request
    logger.info(
        f"Request started",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "client": request.client.host
        }
    )
    
    response = await call_next(request)
    
    # Log response
    duration = time.time() - start_time
    logger.info(
        f"Request completed",
        extra={
            "request_id": request_id,
            "status_code": response.status_code,
            "duration_ms": int(duration * 1000)
        }
    )
    
    response.headers["X-Request-ID"] = request_id
    return response
```

## Next Steps

- ✅ Configuration customized
- 🚀 [Deploy infrastructure](./01-DEPLOY-INFRASTRUCTURE.md)
- 🧪 [Test locally](./02-TEST-LOCALLY.md)
- 📦 [Set up CI/CD](./04-SETUP-GITHUB-ACTIONS.md)
- ✨ [Add advanced features](./05-ADD-FEATURES.md)
