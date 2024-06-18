# Outputs

output "ecs_cluster_name" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.cluster.name
}

# Output for ECS Service Name
output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.service.name
}

output "ecs_alarm_notifications_topic_arn" {
  description = "SNS topic ARN for ECS alarm notifications"
  value       = aws_sns_topic.ecs_alarm_notifications.arn
}

output "ecs_alarm_notifications_topic_name" {
  description = "Name of the SNS topic for ECS alarm notifications"
  value       = aws_sns_topic.ecs_alarm_notifications.name
}

# Output for "envs" secret name
output "envs_secret_name" {
  description = "The name of the 'envs' secret."
  value       = aws_secretsmanager_secret.envs.name
}

# Output for "my_secrets" secret name
output "my_secrets_secret_name" {
  description = "The name of the 'my_secrets' secret."
  value       = aws_secretsmanager_secret.my_secrets.name
}

# Output for "my_secrets" secret arn
output "my_secrets_secret_arn" {
  description = "The name of the 'my_secrets' secret."
  value       = aws_secretsmanager_secret.my_secrets.arn
}

# Output for "openai_api_key" secret name
output "openai_api_key_secret_name" {
  description = "The name of the 'openai_api_key' secret."
  value       = aws_secretsmanager_secret.openai_api_key.name
}

# Output for "openai_endpoints" secret name
output "openai_endpoints_secret_name" {
  description = "The name of the 'openai_endpoints' secret."
  value       = aws_secretsmanager_secret.openai_endpoints.name
}

# Output for "openai_endpoints" secret arn
output "openai_endpoints_secret_arn" {
  description = "The name of the 'openai_endpoints' secret."
  value       = aws_secretsmanager_secret.openai_endpoints.arn
}
