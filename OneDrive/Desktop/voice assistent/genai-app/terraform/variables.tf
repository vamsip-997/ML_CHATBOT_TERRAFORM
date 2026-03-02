# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "genai-chatbot"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "dev"
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ECS Configuration
variable "ecs_task_cpu" {
  description = "CPU units for ECS task"
  type        = string
  default     = "512"
}

variable "ecs_task_memory" {
  description = "Memory for ECS task"
  type        = string
  default     = "1024"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 4
}

# ECR Configuration
variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "app_version" {
  description = "Application version/tag"
  type        = string
  default     = "latest"
}

# CORS Configuration
variable "cors_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

# Bedrock Knowledge Base Configuration
variable "enable_bedrock_kb" {
  description = "Enable Bedrock Knowledge Base (requires OpenSearch Serverless)"
  type        = bool
  default     = true
}

# OpenAI Configuration
variable "openai_model" {
  description = "OpenAI model to use (e.g., gpt-4, gpt-3.5-turbo)"
  type        = string
  default     = "gpt-4"
}

variable "openai_api_key" {
  description = "OpenAI API key (will be stored in SSM Parameter Store)"
  type        = string
  sensitive   = true
}
