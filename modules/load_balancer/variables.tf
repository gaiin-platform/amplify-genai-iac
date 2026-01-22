# load_balancer/variables.tf

# VPC Configuration
variable "vpc_name" {
  description = "The name tag for the VPC"
  type        = string
  default     = "main-vpc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)
}

# ALB Configuration
variable "alb_name" {
  description = "The name of the Application Load Balancer"
  type        = string
  default     = "my-alb"
}

variable "alb_security_group_name" {
  description = "The name of the security group for the ALB"
  type        = string
  default     = "gen-ai-alb-sg"
}

variable "alb_logging_bucket_name" {
  description = "S3 bucket name for ALB access logs"
  type        = string
}

# Target Group Configuration
variable "target_group_name" {
  description = "The name of the target group"
  type        = string
  default     = "gen-ai-tg"
}

variable "target_group_port" {
  description = "The port on which targets receive traffic"
  type        = number
  default     = 3000
}

# Domain and DNS Configuration
variable "domain_name" {
  description = "The domain name for the application (e.g., example.com or app.example.com)"
  type        = string
}

variable "app_route53_zone_id" {
  description = "The Route53 hosted zone ID for the domain"
  type        = string
}

variable "root_redirect" {
  description = "Whether to create a redirect from root domain to www subdomain"
  type        = bool
  default     = false
}

# Regional Configuration
variable "region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# Tags
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "amplify-genai"
}
