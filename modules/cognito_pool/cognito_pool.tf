resource "aws_cognito_user_pool" "main" {
  name = var.userpool_name

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }

  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "email"
    required            = true
  }

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "name"
    required            = true
  }
}

schema { 
    attribute_data_type      = "String"
    mutable                  = true
    name                     = "saml_groups"  // can be use with preauth lambda to limit access by group
    required                 = false  // custom attributes can not be required

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

resource "aws_acm_certificate" "cognito_ssl_cert" {
  domain_name       = var.cognito_domain  
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cognito_ssl_cert_validation" {
  certificate_arn         = aws_acm_certificate.cognito_ssl_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cognito_cert_validation : record.fqdn]
}

locals {
  cognito_cert_validation_records = {
    for dvo in aws_acm_certificate.cognito_ssl_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
}

resource "aws_route53_record" "cognito_cert_validation" {
  for_each = local.cognito_cert_validation_records

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.cognito_route53_zone_id 
  records         = [each.value.record]
  ttl             = 60
}

resource "aws_cognito_user_pool_domain" "main" {
  domain          = var.cognito_domain
  certificate_arn = aws_acm_certificate.cognito_ssl_cert.arn  # Referencing the new certificate's ARN
  user_pool_id    = aws_cognito_user_pool.main.id
  depends_on      = [aws_acm_certificate_validation.cognito_ssl_cert_validation] # Ensure the certificate is validated first
}

resource "aws_cognito_user_pool_client" "main" {
  name = var.userpool_name

  user_pool_id                  = aws_cognito_user_pool.main.id
  generate_secret               = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
  access_token_validity                = 24
  id_token_validity                    = 12
  refresh_token_validity               = 1
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  
  explicit_auth_flows = var.disable_public_signup ? ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"] : ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  prevent_user_existence_errors = "ENABLED"
  
  // Set the supported identity providers based on whether SAML IdP is used.
  supported_identity_providers = var.use_saml_idp ? [aws_cognito_identity_provider.saml[0].provider_name] : ["COGNITO"]
}

resource "aws_route53_record" "cognito_auth_custom_domain" {
  zone_id = var.cognito_route53_zone_id
  name    = var.cognito_domain
  type    = "A"
  alias {
    name = "${aws_cognito_user_pool_domain.main.cloudfront_distribution_arn}"
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_cognito_identity_provider" "saml" {
  count = var.use_saml_idp ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = var.provider_name
  provider_type = "SAML"

  attribute_mapping = {
    email       = "E-Mail Address"
    name        = "Name"
    given_name  = "Given Name"
    family_name = "Surname"
    "custom:saml_groups" = "groups"
  }

  provider_details = {
    MetadataURL = var.sp_metadata_url
  }
}
