resource "aws_cognito_user_pool" "main" {
  name = var.userpool_name

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = var.disable_public_signup
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

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "saml_groups" // can be used with preauth lambda to limit access by group
    required            = false         // custom attributes cannot be required

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  dynamic "lambda_config" {
    for_each = var.pre_token_generation_lambda_arn != "" ? [1] : []
    content {
      pre_token_generation = var.pre_token_generation_lambda_arn
    }
  }

  lifecycle {
    ignore_changes = [
      schema
    ]
  }
}

locals {
  is_custom_domain            = length(regexall("\\.", var.cognito_domain)) > 0
  use_existing_cognito_cert   = var.cognito_ssl_certificate_arn != ""
  use_cognito_route53         = var.cognito_route53_zone_id != ""
  needs_cognito_cert_creation = local.is_custom_domain && !local.use_existing_cognito_cert
  resolved_cognito_cert_arn = local.is_custom_domain ? (
    local.use_existing_cognito_cert ? var.cognito_ssl_certificate_arn : aws_acm_certificate.cognito_ssl_cert[0].arn
  ) : null
}

resource "aws_acm_certificate" "cognito_ssl_cert" {
  count             = local.needs_cognito_cert_creation ? 1 : 0
  domain_name       = var.cognito_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cognito_ssl_cert_validation" {
  count                   = local.needs_cognito_cert_creation && local.use_cognito_route53 ? 1 : 0
  certificate_arn         = aws_acm_certificate.cognito_ssl_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cognito_cert_validation : record.fqdn]
}

locals {
  cognito_cert_validation_records = local.needs_cognito_cert_creation ? {
    for dvo in aws_acm_certificate.cognito_ssl_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}
}

resource "aws_route53_record" "cognito_cert_validation" {
  for_each = local.use_cognito_route53 ? local.cognito_cert_validation_records : {}

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.cognito_route53_zone_id
  records         = [each.value.record]
  ttl             = 60
}

# For prefix domains (no dots): certificate_arn is null (Amazon-hosted domain)
# For custom domains (has dots): certificate_arn is required
resource "aws_cognito_user_pool_domain" "main" {
  domain          = var.cognito_domain
  certificate_arn = local.resolved_cognito_cert_arn
  user_pool_id    = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "main" {
  name = var.userpool_name

  user_pool_id                         = aws_cognito_user_pool.main.id
  generate_secret                      = true
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

  // Set the supported identity providers based on what is enabled.
  // We include "COGNITO" here so you can use SSO in parallel with Cognito username/passwords.
  supported_identity_providers = compact([
    "COGNITO",
    var.use_saml_idp ? aws_cognito_identity_provider.saml[0].provider_name : "",
    var.use_entra_id_oidc ? aws_cognito_identity_provider.entra_id[0].provider_name : ""
  ])
}

resource "aws_route53_record" "cognito_auth_custom_domain" {
  count   = local.use_cognito_route53 ? 1 : 0
  zone_id = var.cognito_route53_zone_id
  name    = var.cognito_domain
  type    = "A"
  alias {
    name                   = aws_cognito_user_pool_domain.main.cloudfront_distribution_arn
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_cognito_identity_provider" "saml" {
  count = var.use_saml_idp ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = var.provider_name
  provider_type = "SAML"

  attribute_mapping = {
    email                = "E-Mail Address"
    name                 = "Name"
    given_name           = "Given Name"
    family_name          = "Surname"
    "custom:saml_groups" = "groups"
  }

  provider_details = {
    MetadataURL = var.sp_metadata_url
  }
}

resource "aws_cognito_identity_provider" "entra_id" {
  count = var.use_entra_id_oidc ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "MicrosoftEntraID"
  provider_type = "OIDC"

  provider_details = {
    client_id                 = var.entra_id_client_id
    client_secret             = var.entra_id_client_secret
    attributes_request_method = "GET"
    oidc_issuer               = var.entra_id_issuer_url
    authorize_scopes          = "openid email profile"
  }

  attribute_mapping = {
    email    = "email"
    name     = "name"
    username = "sub"
  }
}
