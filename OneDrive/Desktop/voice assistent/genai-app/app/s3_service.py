"""
S3 Service - Handles file uploads and downloads from S3
"""
import os
import boto3
from typing import Optional, BinaryIO
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class S3Service:
    """Service for interacting with AWS S3"""
    
    def __init__(self):
        self.region = os.getenv("AWS_REGION", "us-east-1")
        self.bucket_name = os.getenv("S3_BUCKET_NAME")
        self.s3_client = boto3.client('s3', region_name=self.region)
        
    def upload_file(self, file_obj: BinaryIO, file_name: str, prefix: str = "uploads") -> str:
        """
        Upload a file to S3
        
        Args:
            file_obj: File object to upload
            file_name: Name of the file
            prefix: S3 prefix/folder (default: "uploads")
            
        Returns:
            S3 key of uploaded file
        """
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            s3_key = f"{prefix}/{timestamp}_{file_name}"
            
            self.s3_client.upload_fileobj(
                file_obj,
                self.bucket_name,
                s3_key,
                ExtraArgs={'ServerSideEncryption': 'AES256'}
            )
            
            logger.info(f"File uploaded successfully to s3://{self.bucket_name}/{s3_key}")
            return s3_key
            
        except Exception as e:
            logger.error(f"Error uploading file to S3: {str(e)}")
            raise
    
    def download_file(self, s3_key: str, local_path: str) -> str:
        """
        Download a file from S3
        
        Args:
            s3_key: S3 key of the file
            local_path: Local path to save the file
            
        Returns:
            Local file path
        """
        try:
            self.s3_client.download_file(
                self.bucket_name,
                s3_key,
                local_path
            )
            
            logger.info(f"File downloaded successfully from s3://{self.bucket_name}/{s3_key}")
            return local_path
            
        except Exception as e:
            logger.error(f"Error downloading file from S3: {str(e)}")
            raise
    
    def get_file_url(self, s3_key: str, expiration: int = 3600) -> str:
        """
        Generate a presigned URL for a file
        
        Args:
            s3_key: S3 key of the file
            expiration: URL expiration time in seconds (default: 1 hour)
            
        Returns:
            Presigned URL
        """
        try:
            url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': s3_key
                },
                ExpiresIn=expiration
            )
            
            return url
            
        except Exception as e:
            logger.error(f"Error generating presigned URL: {str(e)}")
            raise
    
    def list_files(self, prefix: str = "") -> list:
        """
        List files in S3 bucket
        
        Args:
            prefix: S3 prefix to filter files
            
        Returns:
            List of file objects
        """
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=prefix
            )
            
            files = []
            for obj in response.get('Contents', []):
                files.append({
                    'key': obj['Key'],
                    'size': obj['Size'],
                    'last_modified': obj['LastModified'],
                    'etag': obj['ETag']
                })
            
            return files
            
        except Exception as e:
            logger.error(f"Error listing files from S3: {str(e)}")
            raise
    
    def delete_file(self, s3_key: str) -> bool:
        """
        Delete a file from S3
        
        Args:
            s3_key: S3 key of the file to delete
            
        Returns:
            True if successful
        """
        try:
            self.s3_client.delete_object(
                Bucket=self.bucket_name,
                Key=s3_key
            )
            
            logger.info(f"File deleted successfully: s3://{self.bucket_name}/{s3_key}")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting file from S3: {str(e)}")
            raise
