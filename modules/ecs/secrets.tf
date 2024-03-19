resource "aws_secretsmanager_secret" "env_vars" {
  name        = var.env_vars_name
  description = "Store environment and application specific secrets"
}

resource "aws_secretsmanager_secret_version" "env_vars_version" {
  secret_id     = aws_secretsmanager_secret.env_vars.id
  secret_string = jsonencode(var.env_vars)
}

resource "aws_secretsmanager_secret" "my_secrets" {
  name        = var.secret_name
  description = "Store environment and application specific secrets"
}

resource "aws_secretsmanager_secret_version" "my_secrets_version" {
  secret_id     = aws_secretsmanager_secret.my_secrets.id
  secret_string = jsonencode(var.secrets)
}
