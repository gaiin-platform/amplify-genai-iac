resource "aws_cognito_user_pool" "main" {
  name = var.userpool_name_module_var

  username_configuration {
    case_sensitive = false
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
    attribute_data_type      = "String"
    mutable                  = true
    name                     = "custom:vu_groups"  // Custom attributes must be prefixed with "custom:"
    required                 = false  // custom attributes can not be required

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }  
  schema { 
    attribute_data_type      = "String"
    mutable                  = true
    name                     = "vu_groups"  // 
    required                 = false  // custom attributes can not be required

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }
  # Add Pre-Authentication Lambda Trigger
  lambda_config {
    pre_authentication = aws_lambda_function.pre_auth_trigger.arn
  } 
}



resource "aws_cognito_user_pool_domain" "main" {
  domain          = var.cognito_domain_module_var
  certificate_arn = var.certificate_arn_module_var
  user_pool_id    = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "main" {
  name = var.userpool_name_module_var

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  callback_urls                        = var.callback_urls_module_var
  logout_urls                          = var.logout_urls_module_var
  access_token_validity                = 24
  id_token_validity                    = 12
  refresh_token_validity               = 1
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  explicit_auth_flows           = ["ALLOW_REFRESH_TOKEN_AUTH"]
  generate_secret               = true
  prevent_user_existence_errors = "ENABLED"
  user_pool_id                  = aws_cognito_user_pool.main.id
  supported_identity_providers  = [aws_cognito_identity_provider.saml.provider_name]

}

resource "aws_route53_record" "cognito_auth_custom_domain" {
  zone_id = var.route53_zone_id_var
  name    = var.cognito_domain_module_var
  type    = "A"
  alias {
    name = "${aws_cognito_user_pool_domain.main.cloudfront_distribution_arn}"
    // The following zone id is CloudFront.
    // See https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-aliastarget.html
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}




resource "aws_cognito_identity_provider" "saml" {
  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = var.provider_name_module_var
  provider_type = "SAML"

  attribute_mapping = {
    email       = "E-Mail Address"
    name        = "Name"
    given_name  = "Given Name"
    family_name = "Surname"
    "custom:vu_groups" = "groups"
  }

  provider_details = {
    MetadataURL = var.sp_metadata_url_module_var
  }
}

