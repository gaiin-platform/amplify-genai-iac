variable "cognito_domain_module_var" {
  description = "Enter a string. Must be alpha numeric 3-63 in length."
  type        = string
}

variable "userpool_name_module_var" {
  description = "Enter name for Userpool"
  type        = string
}

variable "provider_name_module_var" {
  description = "Enter name for Userpool"
  type        = string
}

variable "certificate_arn_module_var" {
  description = "Enter the Certificate arn used for Cognito Domain"
  type        = string
}

variable "sp_metadata_url_module_var" {
  description = "Enter the SAML provider metadata file location"
  type        = string
}

variable "callback_urls_module_var" {
  description = "Enter Call Back Urls for SSO"
  type        = list(string)
}

variable "logout_urls_module_var" {
  description = "Enter Logout Urls for SSO"
  type        = list(string)

}

variable "route53_zone_id_var" {
  description = "Enter Route53 Zone ID"
  type        = string
  default = "Z06224743NV1TA1CWL9HY"
  
}



