# ecr/outputs.tf

output "repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app_repository.repository_url
}

output "repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.app_repository.arn
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.app_repository.name
}

output "registry_id" {
  description = "The registry ID where the repository was created"
  value       = aws_ecr_repository.app_repository.registry_id
}

# Legacy outputs for backward compatibility
output "ecr_image_repository_url" {
  description = "(Deprecated: use repository_url) The URL of the ECR repository"
  value       = aws_ecr_repository.app_repository.repository_url
}

output "ecr_image_repository_arn" {
  description = "(Deprecated: use repository_arn) The ARN of the ECR repository"
  value       = aws_ecr_repository.app_repository.arn
}

output "ecr_image_repository_name" {
  description = "(Deprecated: use repository_name) The name of the ECR repository"
  value       = aws_ecr_repository.app_repository.name
}
