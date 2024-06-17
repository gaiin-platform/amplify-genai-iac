resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = var.cloudwatch_log_group_name
  retention_in_days = 90
}
