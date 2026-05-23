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
  default     = ""
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
  type        = string
  default     = ""
}

variable "cognito_ssl_certificate_arn" {
  description = "ARN of an existing ACM certificate for Cognito custom domain. If provided, skips certificate creation."
  type        = string
  default     = ""
}

variable "use_entra_id_oidc" {
  description = "Whether to use Microsoft Entra ID (OIDC) for authentication"
  type        = bool
  default     = false
}

variable "entra_id_client_id" {
  description = "Client ID for Microsoft Entra ID OIDC"
  type        = string
  default     = ""
}

variable "entra_id_client_secret" {
  description = "Client Secret for Microsoft Entra ID OIDC"
  type        = string
  default     = ""
  sensitive   = true
}

variable "entra_id_issuer_url" {
  description = "Issuer URL for Microsoft Entra ID OIDC (e.g. https://login.microsoftonline.com/<TENANT_ID>/v2.0)"
  type        = string
  default     = ""
}

variable "pre_token_generation_lambda_arn" {
  description = "ARN of an existing Lambda function to attach as the Pre Token Generation trigger. Leave empty to skip."
  type        = string
  default     = ""
}
