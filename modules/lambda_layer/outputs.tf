# lambda_layer/outputs.tf

output "layer_arn" {
  description = "The ARN of the Lambda layer"
  value       = aws_lambda_layer_version.panddoc_lambda_layer.arn
}

output "layer_version" {
  description = "The version number of the Lambda layer"
  value       = aws_lambda_layer_version.panddoc_lambda_layer.version
}

# Legacy output for backward compatibility
output "pandoc_lambda_layer_arn" {
  description = "(Deprecated: use layer_arn) The ARN of the Pandoc Lambda layer"
  value       = aws_lambda_layer_version.panddoc_lambda_layer.arn
}
