output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool_client.main.id
  description = "The UserPool App Client ID"
}

output "user_pool_arn" {
  value       = aws_cognito_user_pool.main.arn
  description = "ID of the App Client"
}

output "user_pool_domain" {
  value       = aws_cognito_user_pool_domain.main.domain
  description = "Custom Domain"
}