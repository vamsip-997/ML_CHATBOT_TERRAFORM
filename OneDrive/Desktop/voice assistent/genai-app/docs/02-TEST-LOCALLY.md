# Test Application Locally

This guide shows you how to run and test the GenAI Chatbot locally using Python or Docker.

## Option 1: Run with Python

### Prerequisites

- Python 3.11 or higher
- AWS credentials configured
- pip package manager

### Step 1: Set Up Python Environment

```bash
# Navigate to project directory
cd genai-app

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate

# On Windows:
venv\Scripts\activate

# Upgrade pip
pip install --upgrade pip
```

### Step 2: Install Dependencies

```bash
# Install all required packages
pip install -r requirements.txt

# Verify installation
pip list
```

### Step 3: Configure Environment Variables

```bash
# Copy example environment file
cp .env.example .env
```

Edit `.env` file with your AWS configuration:

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here

# Bedrock Configuration
BEDROCK_KB_ID=your_knowledge_base_id_here
BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0

# S3 Configuration
S3_BUCKET_NAME=your_bucket_name_here

# Application Configuration
PORT=8000
ENV=development
CORS_ORIGINS=http://localhost:3000,http://localhost:8000

# Logging
LOG_LEVEL=INFO
```

### Step 4: Run the Application

```bash
# Start the server with auto-reload
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or use the main.py directly
python -m app.main
```

Expected output:
```
INFO:     Will watch for changes in these directories: ['/path/to/genai-app']
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [12345] using StatReload
INFO:     Started server process [12346]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### Step 5: Access the Application

Open your browser and navigate to:

- **API Root**: http://localhost:8000/
- **Interactive API Docs**: http://localhost:8000/docs
- **Alternative Docs**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

## Option 2: Run with Docker

### Prerequisites

- Docker installed and running
- AWS credentials
- Docker Compose (optional)

### Step 1: Build Docker Image

```bash
# Navigate to project directory
cd genai-app

# Build the Docker image
docker build -t genai-chatbot:local .

# Verify image was created
docker images | grep genai-chatbot
```

### Step 2: Run Container

```bash
# Run with environment variables
docker run -d \
  --name genai-chatbot \
  -p 8000:8000 \
  -e AWS_REGION=us-east-1 \
  -e AWS_ACCESS_KEY_ID=your_access_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret_key \
  -e BEDROCK_KB_ID=your_kb_id \
  -e S3_BUCKET_NAME=your_bucket_name \
  genai-chatbot:local

# Or run with .env file
docker run -d \
  --name genai-chatbot \
  -p 8000:8000 \
  --env-file .env \
  genai-chatbot:local
```

### Step 3: Verify Container is Running

```bash
# Check container status
docker ps | grep genai-chatbot

# View logs
docker logs genai-chatbot

# Follow logs in real-time
docker logs -f genai-chatbot

# Check health
curl http://localhost:8000/health
```

### Step 4: Docker Compose (Optional)

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  genai-chatbot:
    build: .
    container_name: genai-chatbot
    ports:
      - "8000:8000"
    env_file:
      - .env
    environment:
      - ENV=development
    volumes:
      - ./app:/app/app  # Mount for hot-reload during development
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import requests; requests.get('http://localhost:8000/health')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

Run with Docker Compose:

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up -d --build
```

## Testing the API

### Using cURL

#### 1. Health Check

```bash
curl http://localhost:8000/health
```

Response:
```json
{
  "status": "healthy",
  "service": "genai-chatbot"
}
```

#### 2. Chat with Knowledge Base

```bash
curl -X POST http://localhost:8000/api/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What products does the company offer?",
    "use_kb": true
  }'
```

Response:
```json
{
  "response": "Based on the company documents...",
  "session_id": "session-123",
  "citations": [
    {
      "text": "...",
      "location": {...}
    }
  ]
}
```

#### 3. Retrieve Documents

```bash
curl -X POST http://localhost:8000/api/v1/retrieve \
  -H "Content-Type: application/json" \
  -d '{
    "query": "financial data",
    "max_results": 5
  }'
```

#### 4. Upload File

```bash
curl -X POST http://localhost:8000/api/v1/upload \
  -F "file=@/path/to/document.pdf"
```

Response:
```json
{
  "message": "File uploaded successfully",
  "s3_key": "uploads/20240228_120000_document.pdf",
  "url": "https://s3.amazonaws.com/..."
}
```

#### 5. List Files

```bash
curl http://localhost:8000/api/v1/files?prefix=uploads
```

#### 6. Delete File

```bash
curl -X DELETE http://localhost:8000/api/v1/files/uploads/20240228_120000_document.pdf
```

### Using Python Requests

Create `test_api.py`:

```python
import requests
import json

BASE_URL = "http://localhost:8000"

def test_health():
    response = requests.get(f"{BASE_URL}/health")
    print(f"Health Check: {response.json()}")

def test_chat(query):
    response = requests.post(
        f"{BASE_URL}/api/v1/chat",
        json={
            "query": query,
            "use_kb": True
        }
    )
    print(f"Chat Response: {json.dumps(response.json(), indent=2)}")

def test_retrieve(query):
    response = requests.post(
        f"{BASE_URL}/api/v1/retrieve",
        json={
            "query": query,
            "max_results": 3
        }
    )
    print(f"Retrieved Documents: {json.dumps(response.json(), indent=2)}")

def test_upload(file_path):
    with open(file_path, 'rb') as f:
        files = {'file': f}
        response = requests.post(f"{BASE_URL}/api/v1/upload", files=files)
    print(f"Upload Response: {response.json()}")

if __name__ == "__main__":
    test_health()
    test_chat("What is the company's mission?")
    test_retrieve("company overview")
    # test_upload("sample.pdf")
```

Run the tests:
```bash
python test_api.py
```

### Using Postman

1. **Import Collection**: Create a new collection in Postman
2. **Set Base URL**: Add variable `{{base_url}}` = `http://localhost:8000`
3. **Add Requests**:
   - GET `{{base_url}}/health`
   - POST `{{base_url}}/api/v1/chat` with JSON body
   - POST `{{base_url}}/api/v1/upload` with form-data

### Using HTTPie

```bash
# Install HTTPie
pip install httpie

# Health check
http GET localhost:8000/health

# Chat
http POST localhost:8000/api/v1/chat \
  query="What products do you offer?" \
  use_kb:=true

# Upload file
http -f POST localhost:8000/api/v1/upload \
  file@document.pdf
```

## Interactive Testing with Swagger UI

1. Open http://localhost:8000/docs
2. Click on any endpoint
3. Click "Try it out"
4. Fill in parameters
5. Click "Execute"
6. View response

## Debugging

### Enable Debug Logging

Edit `.env`:
```bash
LOG_LEVEL=DEBUG
```

Or set when running:
```bash
LOG_LEVEL=DEBUG uvicorn app.main:app --reload
```

### Common Issues

**Issue: Module not found**
```bash
# Ensure you're in the virtual environment
which python  # Should show venv path

# Reinstall dependencies
pip install -r requirements.txt
```

**Issue: AWS credentials not found**
```bash
# Check AWS configuration
aws configure list

# Or set credentials in .env
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

**Issue: Connection to Bedrock fails**
```bash
# Verify Bedrock is available in your region
aws bedrock list-foundation-models --region us-east-1

# Check KB exists
aws bedrock-agent get-knowledge-base --knowledge-base-id YOUR_KB_ID
```

**Issue: Port already in use**
```bash
# Find process using port 8000
# macOS/Linux:
lsof -i :8000

# Windows:
netstat -ano | findstr :8000

# Kill the process or use different port
uvicorn app.main:app --reload --port 8001
```

## Development Tips

### Hot Reload

When running with `--reload`, changes to Python files will automatically restart the server:

```bash
uvicorn app.main:app --reload
```

### Code Formatting

```bash
# Install development tools
pip install black flake8 pytest

# Format code
black app/

# Lint code
flake8 app/ --max-line-length=120

# Run type checking (if you add type hints)
pip install mypy
mypy app/
```

### Testing

Create `tests/test_routes.py`:

```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_chat():
    response = client.post(
        "/api/v1/chat",
        json={"query": "test", "use_kb": False}
    )
    assert response.status_code == 200
```

Run tests:
```bash
pytest tests/ -v
```

## Performance Testing

### Using Apache Bench

```bash
# Install ab (usually comes with Apache)
# Test health endpoint
ab -n 100 -c 10 http://localhost:8000/health
```

### Using wrk

```bash
# Install wrk
brew install wrk  # macOS
apt-get install wrk  # Ubuntu

# Run load test
wrk -t4 -c100 -d30s http://localhost:8000/health
```

## Cleanup

### Stop Python Server
```bash
# Press Ctrl+C in the terminal where uvicorn is running
```

### Stop Docker Container
```bash
# Stop container
docker stop genai-chatbot

# Remove container
docker rm genai-chatbot

# Remove image (optional)
docker rmi genai-chatbot:local
```

### Stop Docker Compose
```bash
docker-compose down

# Remove volumes
docker-compose down -v
```

## Next Steps

1. ✅ Application running locally
2. 🚀 [Deploy infrastructure](./01-DEPLOY-INFRASTRUCTURE.md)
3. ⚙️ [Customize configuration](./03-CUSTOMIZE-CONFIG.md)
4. 📦 [Set up CI/CD](./04-SETUP-GITHUB-ACTIONS.md)
5. ✨ [Add advanced features](./05-ADD-FEATURES.md)
