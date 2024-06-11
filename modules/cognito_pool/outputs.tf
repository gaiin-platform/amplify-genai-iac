output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.main.id
  description = "The UserPool ID"
}

output "user_pool_domain" {
  value       = aws_cognito_user_pool_domain.main.domain
  description = "Custom Domain"
}

output "cognito_user_pool_url" {
  value = aws_cognito_user_pool.main.endpoint
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.main.id
}

output "cognito_user_pool_client_secret" {
  value = aws_cognito_user_pool_client.main.client_secret
}