variable "cognito_domain" {
  description = "Enter a string. Must be alpha numeric 3-63 in length."
  type        = string
}

variable "userpool_name" {
  description = "Enter name for Userpool"
  type        = string
}

variable "provider_name" {
  description = "Enter name for Userpool"
  type        = string
}

variable "sp_metadata_url" {
  description = "Enter the SAML provider metadata file location"
  type        = string
}

variable "callback_urls" {
  description = "Enter Call Back Urls for SSO"
  type        = list(string)
}

variable "logout_urls" {
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

variable "use_saml_idp" {
  description = "Whether to create a SAML IdP for the Cognito user pool"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain Name"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate"
  type        = string
}


variable "disable_public_signup" {
  description = "Whether to disable public sign-up in the hosted UI"
  type        = bool
  default     = true
}


variable "cognito_route53_zone_id" {
  description = "The Route53 hosted zone ID for the domain"
}

