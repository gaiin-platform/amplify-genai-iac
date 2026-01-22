# =============================================================================
# Amplify GenAI Infrastructure Variables
# =============================================================================
# This file defines all variables with validation rules and descriptions
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Account Configuration
# -----------------------------------------------------------------------------

variable "aws_account_id" {
  description = "AWS Account ID where resources will be deployed (12-digit number)"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be exactly 12 digits."
  }
}

variable "aws_region" {
  description = "AWS Region for resource deployment (e.g., us-east-1, eu-west-1)"
  type        = string
  default     = "us-east-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS Region must be in format: us-east-1, eu-west-1, ap-south-1, etc."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, or prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  description = "Alias for aws_region (for backward compatibility)"
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Domain Configuration
# -----------------------------------------------------------------------------

variable "application_domain" {
  description = "Domain name for the application (e.g., chat.example.com)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-\\.]*[a-z0-9]$", var.application_domain))
    error_message = "Application domain must be a valid domain name (lowercase letters, numbers, hyphens, and dots only)."
  }
}

variable "domain_name" {
  description = "Alias for application_domain (for backward compatibility)"
  type        = string
  default     = ""
}

variable "cognito_domain" {
  description = "Cognito domain prefix or custom domain (e.g., auth.example.com or auth-myapp)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-\\.]*[a-z0-9]$", var.cognito_domain))
    error_message = "Cognito domain must be a valid domain name or prefix (lowercase letters, numbers, hyphens, and dots only)."
  }
}

variable "app_route53_zone_id" {
  description = "Route53 Hosted Zone ID for the application domain"
  type        = string
  validation {
    condition     = can(regex("^Z[A-Z0-9]+$", var.app_route53_zone_id))
    error_message = "Route53 Hosted Zone ID must start with Z followed by alphanumeric characters."
  }
}

variable "cognito_route53_zone_id" {
  description = "Route53 Hosted Zone ID for Cognito custom domain (leave empty if using Cognito prefix)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM Certificate ARN for HTTPS (must be in the same region)"
  type        = string
  default     = ""
  validation {
    condition     = var.acm_certificate_arn == "" || can(regex("^arn:aws:acm:[a-z0-9-]+:[0-9]{12}:certificate/[a-f0-9-]+$", var.acm_certificate_arn))
    error_message = "ACM Certificate ARN must be a valid ARN or empty."
  }
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for VPC (e.g., 10.0.0.0/16)"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (must be within VPC CIDR)"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (must be within VPC CIDR)"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

variable "vpc_id" {
  description = "VPC ID (leave empty for new VPC creation)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Resource Naming
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource tagging and organization"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "main-vpc"
}

variable "alb_name" {
  description = "Name for the Application Load Balancer"
  type        = string
  default     = "amplifygenai-alb"
}

variable "cluster_name" {
  description = "Name for the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name for the ECS service"
  type        = string
}

variable "ecr_repo_name" {
  description = "Name for the ECR repository"
  type        = string
  default     = "amplifygenai-repo"
}

variable "userpool_name" {
  description = "Name for the Cognito User Pool"
  type        = string
  default     = "AmplifyGenAI-UserPool"
}

# -----------------------------------------------------------------------------
# Notification Configuration
# -----------------------------------------------------------------------------

variable "ecs_alarm_email" {
  description = "Email address for ECS scaling alarms and notifications"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.ecs_alarm_email))
    error_message = "ECS alarm email must be a valid email address."
  }
}


# -----------------------------------------------------------------------------
# ECS Configuration
# -----------------------------------------------------------------------------

variable "container_cpu" {
  description = "CPU units for the ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 1024
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.container_cpu)
    error_message = "Container CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "container_memory" {
  description = "Memory in MB for the ECS task (must be compatible with CPU)"
  type        = number
  default     = 4096
  validation {
    condition     = contains([512, 1024, 2048, 4096, 8192, 16384, 30720], var.container_memory)
    error_message = "Container memory must be one of: 512, 1024, 2048, 4096, 8192, 16384, 30720."
  }
}

variable "desired_count" {
  description = "Desired number of ECS tasks to run"
  type        = number
  default     = 1
  validation {
    condition     = var.desired_count >= 1
    error_message = "Desired count must be at least 1."
  }
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
  default     = 1
  validation {
    condition     = var.min_capacity >= 1
    error_message = "Minimum capacity must be at least 1."
  }
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 5
  validation {
    condition     = var.max_capacity >= var.min_capacity
    error_message = "Maximum capacity must be greater than or equal to minimum capacity."
  }
}

variable "scale_target_value" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 75
  validation {
    condition     = var.scale_target_value > 0 && var.scale_target_value <= 100
    error_message = "Scale target value must be between 1 and 100."
  }
}

variable "scale_in_cooldown" {
  description = "Cooldown period in seconds after scaling in"
  type        = number
  default     = 300
  validation {
    condition     = var.scale_in_cooldown >= 0
    error_message = "Scale in cooldown must be non-negative."
  }
}

variable "scale_out_cooldown" {
  description = "Cooldown period in seconds after scaling out"
  type        = number
  default     = 300
  validation {
    condition     = var.scale_out_cooldown >= 0
    error_message = "Scale out cooldown must be non-negative."
  }
}

variable "container_port" {
  description = "Port number the container listens on"
  type        = number
  default     = 3000
  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}

variable "container_name" {
  description = "Name of the container (DO NOT CHANGE - referenced by backend)"
  type        = string
  default     = "amplifyApp"
}

# -----------------------------------------------------------------------------
# ECR Configuration
# -----------------------------------------------------------------------------

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "IMMUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push to ECR"
  type        = bool
  default     = false
}

variable "ecr_image_repository_arn" {
  description = "ECR repository ARN (leave empty for new repository)"
  type        = string
  default     = ""
}

variable "ecr_image_repository_url" {
  description = "ECR repository URL (leave empty for new repository)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Load Balancer Configuration
# -----------------------------------------------------------------------------

variable "target_group_port" {
  description = "Port for the ALB target group (should match container_port)"
  type        = number
  default     = 3000
  validation {
    condition     = var.target_group_port > 0 && var.target_group_port <= 65535
    error_message = "Target group port must be between 1 and 65535."
  }
}

variable "target_group_name" {
  description = "Name for the ALB target group"
  type        = string
  default     = "amplifygenai-tg"
}

variable "alb_security_group_name" {
  description = "Name for the ALB security group"
  type        = string
  default     = "amplifygenai-sg"
}

variable "alb_logging_bucket_name" {
  description = "S3 bucket name for ALB access logs"
  type        = string
  default     = "amplifygenai-alb-access-logs"
}

variable "root_redirect" {
  description = "Enable redirect from root domain to www subdomain"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "Target group ARN (leave empty for new target group)"
  type        = string
  default     = ""
}

variable "alb_sg_id" {
  description = "ALB security group ID (leave empty for new security group)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# CloudWatch Configuration
# -----------------------------------------------------------------------------

variable "cloudwatch_log_group_name" {
  description = "Name for the CloudWatch log group"
  type        = string
  default     = "amplifygenai-loggroup"
}

variable "cloudwatch_log_stream_prefix" {
  description = "Prefix for CloudWatch log streams"
  type        = string
  default     = "ecs"
}

variable "cloudwatch_policy_name" {
  description = "Name for the CloudWatch IAM policy"
  type        = string
  default     = "amplifygenai-cloudwatch-policy"
}

# -----------------------------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------------------------

variable "task_execution_role_name" {
  description = "Name for the ECS task execution IAM role"
  type        = string
  default     = "gen-ai-app-task-execution-role"
}

variable "task_role_name" {
  description = "Name for the ECS task IAM role"
  type        = string
  default     = "gen-ai-app-task-role"
}

variable "task_name" {
  description = "Name for the ECS task definition family"
  type        = string
  default     = "gen-ai-app-task"
}

variable "secret_access_policy_name" {
  description = "Name for the Secrets Manager access IAM policy"
  type        = string
  default     = "amplifygenai-secret-access-policy"
}

variable "ecr_repo_access_policy_name" {
  description = "Name for the ECR repository access IAM policy"
  type        = string
  default     = "amplifygenai-ecr-repo-access-policy"
}

variable "container_exec_policy_name" {
  description = "Name for the ECS container exec IAM policy"
  type        = string
  default     = "amplifygenai-container-exec-policy"
}


# -----------------------------------------------------------------------------
# Cognito Configuration
# -----------------------------------------------------------------------------

variable "provider_name" {
  description = "Name for the Cognito identity provider"
  type        = string
  default     = "AmplifyGenAI"
}

variable "use_saml_idp" {
  description = "Enable SAML identity provider integration"
  type        = bool
  default     = false
}

variable "sp_metadata_url" {
  description = "SAML service provider metadata URL (required if use_saml_idp = true)"
  type        = string
  default     = ""
}

variable "create_pre_auth_lambda" {
  description = "Create pre-authentication Lambda trigger"
  type        = bool
  default     = false
}

variable "disable_public_signup" {
  description = "Disable public user signup (users must be created by admin)"
  type        = bool
  default     = true
}

variable "callback_urls" {
  description = "OAuth callback URLs (auto-generated if empty)"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "OAuth logout URLs (auto-generated if empty)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Secrets Manager Configuration
# -----------------------------------------------------------------------------

variable "openai_api_key_name" {
  description = "Name for OpenAI API key secret (DO NOT CHANGE)"
  type        = string
  default     = "openai-api-key"
}

variable "openai_endpoints_name" {
  description = "Name for OpenAI endpoints secret (DO NOT CHANGE)"
  type        = string
  default     = "openai-endpoints"
}

variable "secret_name" {
  description = "Name for application secrets (DO NOT CHANGE)"
  type        = string
  default     = "amplify-app-secrets"
}

variable "envs_name" {
  description = "Name for application environment variables (DO NOT CHANGE)"
  type        = string
  default     = "amplify-app-vars"
}

variable "secrets" {
  description = "Initial secret values (will be auto-populated during deployment)"
  type        = map(string)
  default = {
    COGNITO_CLIENT_SECRET = ""
    OPENAI_API_KEY        = ""
    NEXTAUTH_SECRET       = ""
  }
  sensitive = true
}

variable "envs" {
  description = "Initial environment variable values (will be auto-populated during deployment)"
  type        = map(string)
  default = {
    API_BASE_URL                = ""
    ASSISTANTS_API_BASE         = ""
    AVAILABLE_MODELS            = "anthropic.claude-3-sonnet-20240229-v1:0,anthropic.claude-3-haiku-20240307-v1:0,gpt-35-turbo,gpt-4-1106-Preview"
    AZURE_API_NAME              = "openai"
    AZURE_DEPLOYMENT_ID         = "gpt-4"
    CHAT_ENDPOINT               = ""
    COGNITO_CLIENT_ID           = ""
    COGNITO_DOMAIN              = ""
    COGNITO_ISSUER              = ""
    DEFAULT_MODEL               = "anthropic.claude-3-haiku-20240307-v1:0"
    DEFAULT_FUNCTION_CALL_MODEL = "gpt-4-1106-Preview"
    MIXPANEL_TOKEN              = ""
    NEXTAUTH_SECRET             = ""
    NEXTAUTH_URL                = ""
    OPENAI_API_HOST             = "https://api.openai.com"
    OPENAI_API_TYPE             = "azure"
    OPENAI_API_VERSION          = "2024-02-15-preview"
  }
  sensitive = true
}

# -----------------------------------------------------------------------------
# Alarm Configuration
# -----------------------------------------------------------------------------

variable "ecs_scale_up_alarm_description" {
  description = "Description for ECS scale up alarm"
  type        = string
  default     = "scaling up due to high CPU utilization"
}

variable "ecs_scale_down_alarm_description" {
  description = "Description for ECS scale down alarm"
  type        = string
  default     = "scaling down due to low CPU utilization"
}

# -----------------------------------------------------------------------------
# Optional: Bedrock Guardrails Configuration
# -----------------------------------------------------------------------------

variable "enable_bedrock_guardrails" {
  description = "Enable AWS Bedrock Guardrails"
  type        = bool
  default     = false
}

variable "bedrock_guardrail_id" {
  description = "Bedrock Guardrail ID (required if enable_bedrock_guardrails = true)"
  type        = string
  default     = ""
}

variable "bedrock_guardrail_version" {
  description = "Bedrock Guardrail version (required if enable_bedrock_guardrails = true)"
  type        = string
  default     = ""
}

# =============================================================================
# End of Variables
# =============================================================================
