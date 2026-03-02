# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-execution"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# SSM Parameter access for ECS task execution (to read secrets)
resource "aws_iam_role_policy" "ecs_task_execution_ssm" {
  name = "${var.project_name}-ecs-execution-ssm"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/${var.environment}/*"
        ]
      }
    ]
  })
}

# ECS Task Role (application permissions)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# S3 access policy for ECS task
resource "aws_iam_role_policy" "ecs_s3_access" {
  name = "${var.project_name}-s3-access"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.genai_documents.arn,
          "${aws_s3_bucket.genai_documents.arn}/*",
          aws_s3_bucket.bedrock_kb_source.arn,
          "${aws_s3_bucket.bedrock_kb_source.arn}/*"
        ]
      }
    ]
  })
}

# Bedrock access policy for ECS task
resource "aws_iam_role_policy" "ecs_bedrock_access" {
  name = "${var.project_name}-bedrock-access"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "bedrock:InvokeModel",
            "bedrock:InvokeModelWithResponseStream"
          ]
          Resource = [
            "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
          ]
        }
      ],
      var.enable_bedrock_kb ? [
        {
          Effect = "Allow"
          Action = [
            "bedrock:Retrieve",
            "bedrock:RetrieveAndGenerate"
          ]
          Resource = [
            aws_bedrockagent_knowledge_base.genai_kb[0].arn
          ]
        }
      ] : []
    )
  })
}

# CloudWatch Logs policy for ECS task
resource "aws_iam_role_policy" "ecs_cloudwatch_logs" {
  name = "${var.project_name}-cloudwatch-logs"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}*"
        ]
      }
    ]
  })
}

# Bedrock Knowledge Base execution role
resource "aws_iam_role" "bedrock_kb_role" {
  count = var.enable_bedrock_kb ? 1 : 0

  name = "${var.project_name}-bedrock-kb-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-bedrock-kb"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# S3 access for Bedrock KB
resource "aws_iam_role_policy" "bedrock_kb_s3_access" {
  count = var.enable_bedrock_kb ? 1 : 0

  name = "${var.project_name}-kb-s3-access"
  role = aws_iam_role.bedrock_kb_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.bedrock_kb_source.arn,
          "${aws_s3_bucket.bedrock_kb_source.arn}/*"
        ]
      }
    ]
  })
}

# Bedrock model access for KB
resource "aws_iam_role_policy" "bedrock_kb_model_access" {
  count = var.enable_bedrock_kb ? 1 : 0

  name = "${var.project_name}-kb-model-access"
  role = aws_iam_role.bedrock_kb_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
        ]
      }
    ]
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Outputs
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "bedrock_kb_role_arn" {
  description = "ARN of the Bedrock Knowledge Base role"
  value       = try(aws_iam_role.bedrock_kb_role[0].arn, "")
}
