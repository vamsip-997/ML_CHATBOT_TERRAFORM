# S3 bucket for document storage and uploads
resource "aws_s3_bucket" "genai_documents" {
  bucket = "${var.project_name}-documents-${var.environment}"

  tags = {
    Name        = "${var.project_name}-documents"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "genai_documents" {
  bucket = aws_s3_bucket.genai_documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "genai_documents" {
  bucket = aws_s3_bucket.genai_documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "genai_documents" {
  bucket = aws_s3_bucket.genai_documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "genai_documents" {
  bucket = aws_s3_bucket.genai_documents.id

  rule {
    id     = "delete-old-uploads"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# CORS configuration for web uploads
resource "aws_s3_bucket_cors_configuration" "genai_documents" {
  bucket = aws_s3_bucket.genai_documents.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = var.cors_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# S3 bucket for Bedrock Knowledge Base data source
resource "aws_s3_bucket" "bedrock_kb_source" {
  bucket = "${var.project_name}-kb-source-${var.environment}"

  tags = {
    Name        = "${var.project_name}-kb-source"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Enable versioning for KB source
resource "aws_s3_bucket_versioning" "bedrock_kb_source" {
  bucket = aws_s3_bucket.bedrock_kb_source.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption for KB source
resource "aws_s3_bucket_server_side_encryption_configuration" "bedrock_kb_source" {
  bucket = aws_s3_bucket.bedrock_kb_source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for KB source
resource "aws_s3_bucket_public_access_block" "bedrock_kb_source" {
  bucket = aws_s3_bucket.bedrock_kb_source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output values
output "documents_bucket_name" {
  description = "Name of the S3 bucket for documents"
  value       = aws_s3_bucket.genai_documents.id
}

output "documents_bucket_arn" {
  description = "ARN of the S3 bucket for documents"
  value       = aws_s3_bucket.genai_documents.arn
}

output "kb_source_bucket_name" {
  description = "Name of the S3 bucket for KB source"
  value       = aws_s3_bucket.bedrock_kb_source.id
}

output "kb_source_bucket_arn" {
  description = "ARN of the S3 bucket for KB source"
  value       = aws_s3_bucket.bedrock_kb_source.arn
}
