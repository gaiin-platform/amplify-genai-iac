resource "aws_bedrock_guardrail" "bedrock_guardrail" {
  count       = var.guardrail_enabled ? 1 : 0
  name        = var.guardrail_name
  description = var.guardrail_description

  blocked_input_messaging  = var.blocked_input_messaging
  blocked_outputs_messaging = var.blocked_outputs_messaging

  dynamic "topic_policy_config" {
    for_each = length(var.topics) > 0 ? [1] : []
    content {
      dynamic "topics_config" {
        for_each = var.topics
        content {
          name       = topics_config.value.name
          examples   = topics_config.value.examples
          type       = topics_config.value.type
          definition = topics_config.value.definition
        }
      }
    }
  }
}
