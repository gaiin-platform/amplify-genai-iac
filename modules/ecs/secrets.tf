resource "aws_secretsmanager_secret" "envs" {
  name        = var.envs_name
  description = "Store environment and application specific secrets"
}

resource "aws_secretsmanager_secret_version" "envs_version" {
  secret_id     = aws_secretsmanager_secret.envs.id
  secret_string = jsonencode(var.envs)
}

resource "aws_secretsmanager_secret" "my_secrets" {
  name        = var.secret_name
  description = "Store environment and application specific secrets"
}

resource "aws_secretsmanager_secret_version" "my_secrets_version" {
  secret_id     = aws_secretsmanager_secret.my_secrets.id
  secret_string = jsonencode(var.secrets)
}

resource "aws_secretsmanager_secret" "openai_api_key" {
  name        = var.openai_api_key_name
  description = "Store openai api key"
}

resource "aws_secretsmanager_secret_version" "openai_api_key_version" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = jsonencode("")
}

resource "aws_secretsmanager_secret" "openai_endpoints" {
  name        = var.openai_endpoints_name
  description = "Store openai endpoints and key"
}

resource "aws_secretsmanager_secret_version" "openai_endpoints_version" {
  secret_id     = aws_secretsmanager_secret.openai_endpoints.id
  secret_string = jsonencode("")
}
