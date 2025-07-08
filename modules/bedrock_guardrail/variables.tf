variable "guardrail_enabled" {
  description = "Enable or disable the Bedrock Guardrail resource"
  type        = bool
  default     = false
}

variable "guardrail_name" {
  description = "Name for the Bedrock Guardrail"
  type        = string
}

variable "guardrail_description" {
  description = "Description for the Bedrock Guardrail resource"
  type        = string
  default     = "Amplify's Bedrock Guardrail description"
}

variable "blocked_input_messaging" {
  description = "Message to return when the guardrail blocks a prompt (input)"
  type        = string
  default     = "Your request was blocked due to policy restrictions."
}

variable "blocked_outputs_messaging" {
  description = "Message to return when the guardrail blocks a model response (output)"
  type        = string
  default     = "The model's response was blocked due to policy restrictions."
}



variable "topics" {
  description = "List of topics to block, each as an object with name, examples, type, and definition"
  type = list(object({
    name       = string
    examples   = list(string)
    type       = string
    definition = string
  }))
  default = []
}
