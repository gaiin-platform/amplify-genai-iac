output "pandoc_lambda_layer_arn" {
  value = aws_lambda_layer_version.panddoc_lambda_layer.arn
  description = "The ARN for the existing version of the Pandoc Lambda layer."
}
