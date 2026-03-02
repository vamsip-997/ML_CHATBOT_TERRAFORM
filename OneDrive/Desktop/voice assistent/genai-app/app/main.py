"""
Main FastAPI application for GenAI Chatbot
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import os

from .routes import router

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="GenAI Chatbot API",
    description="AI-powered chatbot using AWS Bedrock and Knowledge Base",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(router, prefix="/api/v1", tags=["chatbot"])


@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info("Starting GenAI Chatbot API...")
    logger.info(f"AWS Region: {os.getenv('AWS_REGION', 'us-east-1')}")
    logger.info(f"Bedrock KB ID: {os.getenv('BEDROCK_KB_ID', 'Not configured')}")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down GenAI Chatbot API...")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "GenAI Chatbot API",
        "version": "1.0.0",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8000)),
        reload=os.getenv("ENV", "production") == "development"
    )
