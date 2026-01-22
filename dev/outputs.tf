# dev/outputs.tf
# Comprehensive outputs from all infrastructure modules

# ============================================================================
# VPC and Network Outputs
# ============================================================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.load_balancer.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.load_balancer.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.load_balancer.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.load_balancer.private_subnet_ids
}

# ============================================================================
# Application Load Balancer Outputs
# ============================================================================

output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = module.load_balancer.alb_arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.load_balancer.alb_dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = module.load_balancer.alb_zone_id
}

output "alb_security_group_id" {
  description = "The security group ID of the Application Load Balancer"
  value       = module.load_balancer.alb_security_group_id
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = module.load_balancer.target_group_arn
}

# ============================================================================
# Route53 and SSL Outputs
# ============================================================================

output "route53_record_fqdn" {
  description = "The FQDN of the Route53 record pointing to the ALB"
  value       = module.load_balancer.route53_record_fqdn
}

output "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate"
  value       = module.load_balancer.ssl_certificate_arn
}

# ============================================================================
# ECS Cluster and Service Outputs
# ============================================================================

output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_id" {
  description = "The ID of the ECS service"
  value       = module.ecs.service_id
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = module.ecs.service_name
}

output "ecs_service_arn" {
  description = "The ARN of the ECS service"
  value       = module.ecs.service_arn
}

output "ecs_task_definition_arn" {
  description = "The ARN of the task definition"
  value       = module.ecs.task_definition_arn
}

output "ecs_task_execution_role_arn" {
  description = "The ARN of the task execution IAM role"
  value       = module.ecs.task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "The ARN of the task IAM role"
  value       = module.ecs.task_role_arn
}

output "ecs_security_group_id" {
  description = "The ID of the ECS task security group"
  value       = module.ecs.security_group_id
}

output "ecs_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = module.ecs.log_group_name
}

output "ecs_log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = module.ecs.log_group_arn
}

# ============================================================================
# ECR Repository Outputs
# ============================================================================

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "ecr_repository_name" {
  description = "The name of the ECR repository"
  value       = module.ecr.repository_name
}

output "ecr_registry_id" {
  description = "The registry ID where the repository was created"
  value       = module.ecr.registry_id
}

# ============================================================================
# Cognito User Pool Outputs
# ============================================================================

output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = module.cognito_pool.user_pool_id
}

output "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = module.cognito_pool.user_pool_arn
}

output "cognito_user_pool_endpoint" {
  description = "The endpoint of the Cognito User Pool"
  value       = module.cognito_pool.user_pool_endpoint
}

output "cognito_user_pool_domain" {
  description = "The domain of the Cognito User Pool"
  value       = module.cognito_pool.user_pool_domain
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = module.cognito_pool.user_pool_client_id
}

output "cognito_user_pool_client_secret" {
  description = "The secret of the Cognito User Pool Client"
  value       = module.cognito_pool.user_pool_client_secret
  sensitive   = true
}

# ============================================================================
# Lambda Layer Outputs
# ============================================================================

output "lambda_layer_arn" {
  description = "The ARN of the Lambda layer"
  value       = module.lambda_layer.layer_arn
}

output "lambda_layer_version" {
  description = "The version number of the Lambda layer"
  value       = module.lambda_layer.layer_version
}

# ============================================================================
# Secrets Manager Outputs
# ============================================================================

output "envs_secret_name" {
  description = "The name of the envs secret in Secrets Manager"
  value       = module.ecs.envs_secret_name
}

output "envs_secret_arn" {
  description = "The ARN of the envs secret in Secrets Manager"
  value       = module.ecs.envs_secret_arn
}

output "my_secrets_secret_name" {
  description = "The name of the my_secrets secret in Secrets Manager"
  value       = module.ecs.my_secrets_secret_name
}

output "my_secrets_secret_arn" {
  description = "The ARN of the my_secrets secret in Secrets Manager"
  value       = module.ecs.my_secrets_secret_arn
}

output "openai_api_key_secret_name" {
  description = "The name of the OpenAI API key secret in Secrets Manager"
  value       = module.ecs.openai_api_key_secret_name
}

output "openai_api_key_secret_arn" {
  description = "The ARN of the OpenAI API key secret in Secrets Manager"
  value       = module.ecs.openai_api_key_secret_arn
}

output "openai_endpoints_secret_name" {
  description = "The name of the OpenAI endpoints secret in Secrets Manager"
  value       = module.ecs.openai_endpoints_secret_name
}

output "openai_endpoints_secret_arn" {
  description = "The ARN of the OpenAI endpoints secret in Secrets Manager"
  value       = module.ecs.openai_endpoints_secret_arn
}

# ============================================================================
# SNS Topic Outputs
# ============================================================================

output "ecs_alarm_notifications_topic_arn" {
  description = "The ARN of the SNS topic for ECS alarm notifications"
  value       = module.ecs.ecs_alarm_notifications_topic_arn
}

output "ecs_alarm_notifications_topic_name" {
  description = "The name of the SNS topic for ECS alarm notifications"
  value       = module.ecs.ecs_alarm_notifications_topic_name
}
