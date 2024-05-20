# Outputs

output "ecs_cluster_name" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.cluster.name
}

output "ecs_service_name" {
  description = "The ARN of the ECS service"
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