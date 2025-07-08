output "guardrail_arn" {
  description = "ARN of the Bedrock Guardrail"
  value       = aws_bedrock_guardrail.bedrock_guardrail[0].guardrail_arn
}

output "guardrail_name" {
  description = "The name of the Bedrock Guardrail."
  value       = var.guardrail_name
}