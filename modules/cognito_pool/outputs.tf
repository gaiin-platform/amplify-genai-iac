# cognito_pool/outputs.tf

output "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "The endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "The domain of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
}

output "user_pool_client_secret" {
  description = "The secret of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.client_secret
  sensitive   = true
}

# Legacy outputs for backward compatibility
output "cognito_user_pool_id" {
  description = "(Deprecated: use user_pool_id) The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_url" {
  description = "(Deprecated: use user_pool_endpoint) The endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "cognito_user_pool_client_id" {
  description = "(Deprecated: use user_pool_client_id) The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_user_pool_client_secret" {
  description = "(Deprecated: use user_pool_client_secret) The secret of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.client_secret
  sensitive   = true
}
