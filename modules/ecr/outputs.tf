output "ecr_image_repository_url" {
  value = aws_ecr_repository.app_repository.repository_url

}

output "ecr_image_repository_arn" {
  value = aws_ecr_repository.app_repository.arn

}