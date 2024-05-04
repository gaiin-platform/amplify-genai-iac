variable "cognito_domain_module" {
  description = "Enter a string. Must be alpha numeric 3-63 in length."
  type        = string
}

variable "userpool_name_module" {
  description = "Enter name for Userpool"
  type        = string
}

variable "provider_name_module" {
  description = "Enter name for Userpool"
  type        = string
}

variable "certificate_arn_module" {
  description = "Enter the Certificate arn used for Cognito Domain"
  type        = string
}

variable "sp_metadata_url_module" {
  description = "Enter the SAML provider metadata file location"
  type        = string
}

variable "callback_urls_module" {
  description = "Enter Call Back Urls for SSO"
  type        = list(string)
}

variable "logout_urls_module" {
  description = "Enter Logout Urls for SSO"
  type        = list(string)

}

variable "route53_zone_id" {
  description = "Enter Route53 Zone ID"
  type        = string
  default = ""
  
}

variable "create_pre_auth_lambda" {
  description = "Whether to create the pre-auth Lambda function"
  type        = bool
  default     = false
}



