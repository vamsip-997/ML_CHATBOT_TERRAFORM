# OpenSearch Serverless Collection for Bedrock Knowledge Base
resource "aws_opensearchserverless_security_policy" "genai_kb_encryption" {
  count = var.enable_bedrock_kb ? 1 : 0

  name = "${var.project_name}-kb-encryption-${var.environment}"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource = [
          "collection/${var.project_name}-kb-${var.environment}"
        ]
      }
    ]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "genai_kb_network" {
  count = var.enable_bedrock_kb ? 1 : 0

  name = "${var.project_name}-kb-network-${var.environment}"
  type = "network"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${var.project_name}-kb-${var.environment}"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_collection" "genai_kb" {
  count = var.enable_bedrock_kb ? 1 : 0

  name = "${var.project_name}-kb-${var.environment}"
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.genai_kb_encryption,
    aws_opensearchserverless_security_policy.genai_kb_network
  ]

  tags = {
    Name        = "${var.project_name}-kb"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Data access policy for OpenSearch Serverless
resource "aws_opensearchserverless_access_policy" "genai_kb" {
  count = var.enable_bedrock_kb ? 1 : 0

  name = "${var.project_name}-kb-access-${var.environment}"
  type = "data"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${var.project_name}-kb-${var.environment}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
        },
        {
          ResourceType = "index"
          Resource = [
            "index/${var.project_name}-kb-${var.environment}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument",
            "aoss:UpdateIndex",
            "aoss:DeleteIndex"
          ]
        }
      ]
      Principal = [
        aws_iam_role.bedrock_kb_role[0].arn
      ]
    }
  ])
}

# Bedrock Knowledge Base
resource "aws_bedrockagent_knowledge_base" "genai_kb" {
  count = var.enable_bedrock_kb ? 1 : 0

  name     = "${var.project_name}-kb-${var.environment}"
  role_arn = aws_iam_role.bedrock_kb_role[0].arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.titan-embed-text-v1"
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.genai_kb[0].arn
      vector_index_name = "bedrock-knowledge-base-index"
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }

  depends_on = [
    aws_opensearchserverless_collection.genai_kb,
    aws_opensearchserverless_access_policy.genai_kb
  ]

  tags = {
    Name        = "${var.project_name}-kb"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Bedrock Knowledge Base Data Source
resource "aws_bedrockagent_data_source" "genai_kb_s3" {
  count = var.enable_bedrock_kb ? 1 : 0

  name              = "${var.project_name}-kb-s3-${var.environment}"
  knowledge_base_id = aws_bedrockagent_knowledge_base.genai_kb[0].id

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.bedrock_kb_source.arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}

# Outputs
output "opensearch_collection_endpoint" {
  description = "Endpoint of the OpenSearch Serverless collection"
  value       = try(aws_opensearchserverless_collection.genai_kb[0].collection_endpoint, "")
}

output "knowledge_base_id" {
  description = "ID of the Bedrock Knowledge Base"
  value       = try(aws_bedrockagent_knowledge_base.genai_kb[0].id, "")
}

output "knowledge_base_arn" {
  description = "ARN of the Bedrock Knowledge Base"
  value       = try(aws_bedrockagent_knowledge_base.genai_kb[0].arn, "")
}

output "data_source_id" {
  description = "ID of the Knowledge Base data source"
  value       = try(aws_bedrockagent_data_source.genai_kb_s3[0].id, "")
}
