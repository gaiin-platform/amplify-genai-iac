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
