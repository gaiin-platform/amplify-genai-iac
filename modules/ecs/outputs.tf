# ecs/outputs.tf

# Cluster Outputs
output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.cluster.id
}

output "cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.cluster.arn
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.cluster.name
}

# Service Outputs
output "service_id" {
  description = "The ID of the ECS service"
  value       = aws_ecs_service.service.id
}

output "service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.service.name
}

output "service_arn" {
  description = "The ARN of the ECS service"
  value       = aws_ecs_service.service.id
}

# Task Definition Outputs
output "task_definition_arn" {
  description = "The ARN of the task definition"
  value       = aws_ecs_task_definition.app_task.arn
}

# IAM Role Outputs
output "task_execution_role_arn" {
  description = "The ARN of the task execution IAM role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "task_role_arn" {
  description = "The ARN of the task IAM role"
  value       = aws_iam_role.ecs_task_role.arn
}

# Security Group Outputs
output "security_group_id" {
  description = "The ID of the ECS task security group"
  value       = aws_security_group.ecs_tasks_sg.id
}

# CloudWatch Log Group Outputs
output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs_log_group.name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs_log_group.arn
}

# SNS Topic Outputs
output "ecs_alarm_notifications_topic_arn" {
  description = "The ARN of the SNS topic for ECS alarm notifications"
  value       = aws_sns_topic.ecs_alarm_notifications.arn
}

output "ecs_alarm_notifications_topic_name" {
  description = "The name of the SNS topic for ECS alarm notifications"
  value       = aws_sns_topic.ecs_alarm_notifications.name
}

# Secrets Manager Outputs
output "envs_secret_name" {
  description = "The name of the envs secret in Secrets Manager"
  value       = aws_secretsmanager_secret.envs.name
}

output "envs_secret_arn" {
  description = "The ARN of the envs secret in Secrets Manager"
  value       = aws_secretsmanager_secret.envs.arn
}

output "my_secrets_secret_name" {
  description = "The name of the my_secrets secret in Secrets Manager"
  value       = aws_secretsmanager_secret.my_secrets.name
}

output "my_secrets_secret_arn" {
  description = "The ARN of the my_secrets secret in Secrets Manager"
  value       = aws_secretsmanager_secret.my_secrets.arn
}

output "openai_api_key_secret_name" {
  description = "The name of the OpenAI API key secret in Secrets Manager"
  value       = aws_secretsmanager_secret.openai_api_key.name
}

output "openai_api_key_secret_arn" {
  description = "The ARN of the OpenAI API key secret in Secrets Manager"
  value       = aws_secretsmanager_secret.openai_api_key.arn
}

output "openai_endpoints_secret_name" {
  description = "The name of the OpenAI endpoints secret in Secrets Manager"
  value       = aws_secretsmanager_secret.openai_endpoints.name
}

output "openai_endpoints_secret_arn" {
  description = "The ARN of the OpenAI endpoints secret in Secrets Manager"
  value       = aws_secretsmanager_secret.openai_endpoints.arn
}

# Legacy outputs for backward compatibility
output "ecs_cluster_name" {
  description = "(Deprecated: use cluster_name) The name of the ECS cluster"
  value       = aws_ecs_cluster.cluster.name
}

output "ecs_service_name" {
  description = "(Deprecated: use service_name) The name of the ECS service"
  value       = aws_ecs_service.service.name
}
