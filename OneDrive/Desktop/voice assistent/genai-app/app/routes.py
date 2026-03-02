"""
API Routes - FastAPI endpoints for the GenAI chatbot
"""
from fastapi import APIRouter, HTTPException, UploadFile, File
from pydantic import BaseModel
from typing import Optional, List
import logging

from .bedrock_service import BedrockService
from .s3_service import S3Service

logger = logging.getLogger(__name__)

router = APIRouter()

# Initialize services
bedrock_service = BedrockService()
s3_service = S3Service()


class ChatRequest(BaseModel):
    """Chat request model"""
    query: str
    session_id: Optional[str] = None
    use_kb: bool = True


class ChatResponse(BaseModel):
    """Chat response model"""
    response: str
    session_id: Optional[str] = None
    citations: Optional[List] = None


class RetrievalRequest(BaseModel):
    """Knowledge base retrieval request"""
    query: str
    max_results: int = 5


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "genai-chatbot"}


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Main chat endpoint - interact with the chatbot
    
    Args:
        request: ChatRequest with query and optional session_id
        
    Returns:
        ChatResponse with generated answer and citations
    """
    try:
        if request.use_kb:
            # Use Bedrock Knowledge Base for RAG
            result = bedrock_service.retrieve_and_generate(
                query=request.query,
                session_id=request.session_id
            )
            
            return ChatResponse(
                response=result['response'],
                session_id=result.get('session_id'),
                citations=result.get('citations', [])
            )
        else:
            # Direct model invocation without KB
            response = bedrock_service.invoke_model(prompt=request.query)
            return ChatResponse(response=response)
            
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/retrieve")
async def retrieve(request: RetrievalRequest):
    """
    Retrieve relevant documents from knowledge base
    
    Args:
        request: RetrievalRequest with query and max_results
        
    Returns:
        List of retrieved documents
    """
    try:
        results = bedrock_service.retrieve_from_kb(
            query=request.query,
            max_results=request.max_results
        )
        
        return {"results": results}
        
    except Exception as e:
        logger.error(f"Error in retrieve endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    """
    Upload a file to S3
    
    Args:
        file: File to upload
        
    Returns:
        S3 key and presigned URL
    """
    try:
        s3_key = s3_service.upload_file(
            file_obj=file.file,
            file_name=file.filename
        )
        
        presigned_url = s3_service.get_file_url(s3_key)
        
        return {
            "message": "File uploaded successfully",
            "s3_key": s3_key,
            "url": presigned_url
        }
        
    except Exception as e:
        logger.error(f"Error in upload endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/files")
async def list_files(prefix: str = ""):
    """
    List files in S3 bucket
    
    Args:
        prefix: Optional prefix to filter files
        
    Returns:
        List of files
    """
    try:
        files = s3_service.list_files(prefix=prefix)
        return {"files": files}
        
    except Exception as e:
        logger.error(f"Error in list files endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/files/{s3_key:path}")
async def delete_file(s3_key: str):
    """
    Delete a file from S3
    
    Args:
        s3_key: S3 key of file to delete
        
    Returns:
        Success message
    """
    try:
        s3_service.delete_file(s3_key)
        return {"message": "File deleted successfully"}
        
    except Exception as e:
        logger.error(f"Error in delete file endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
