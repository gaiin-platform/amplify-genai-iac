module "lambda_layer" {
  source                  = "../modules/lambda_layer"
}

module "load_balancer" {
  source                  = "../modules/load_balancer"
  vpc_cidr                = var.vpc_cidr
  vpc_name                = "${local.env}-${var.vpc_name}"
  private_subnet_cidrs    = var.private_subnet_cidrs
  public_subnet_cidrs     = var.public_subnet_cidrs
  alb_logging_bucket_name = "${local.env}-${var.alb_logging_bucket_name}"
  alb_name                = "${local.env}-${var.alb_name}"
  domain_name             = "${local.env}-${var.domain_name}"
  target_group_name       = "${local.env}-${var.target_group_name}-${var.target_group_port}"
  target_group_port       = var.target_group_port
  alb_security_group_name = "${local.env}-${var.alb_security_group_name}"
  root_redirect           = false
  app_route53_zone_id     = var.app_route53_zone_id
  region                  = var.region
}

module "cognito_pool" {
  source                  = "../modules/cognito_pool"
  depends_on              = [module.load_balancer]
  ssl_certificate_arn     = module.load_balancer.ssl_certificate_arn
  cognito_domain          = "${local.env}-${var.cognito_domain}"
  userpool_name           = "${local.env}-${var.userpool_name}"
  provider_name           = "${local.env}-${var.provider_name}"
  sp_metadata_url         = var.sp_metadata_url
  callback_urls           = ["https://${local.env}-${var.domain_name}/api/auth/callback/cognito", "http://localhost:3000/api/auth/callback/cognito"]
  logout_urls             = ["https://${local.env}-${var.domain_name}", "http://localhost:3000"]
  create_pre_auth_lambda  = var.create_pre_auth_lambda
  use_saml_idp            = var.use_saml_idp
  domain_name             = "${local.env}-${var.domain_name}"
  cognito_route53_zone_id = var.cognito_route53_zone_id
  disable_public_signup   = var.disable_public_signup
}

module "ecr" {
  source        = "../modules/ecr"
  ecr_repo_name = "${local.env}-${var.ecr_repo_name}"
  service_name  = module.ecs.ecs_service_name
  cluster_name  = module.ecs.ecs_cluster_name
  notification_arn = module.ecs.ecs_alarm_notifications_topic_arn
}

module "ecs" {
  source                           = "../modules/ecs"
  depends_on                       = [module.load_balancer]
  cluster_name                     = "${local.env}-${var.cluster_name}"
  container_cpu                    = var.container_cpu
  container_memory                 = var.container_memory
  service_name                     = "${local.env}-${var.service_name}"
  min_capacity                     = var.min_capacity
  cloudwatch_log_group_name        = "${local.env}-${var.cloudwatch_log_group_name}"
  cloudwatch_log_stream_prefix     = var.cloudwatch_log_stream_prefix
  cloudwatch_policy_name           = "${local.env}-${var.cloudwatch_policy_name}"
  secret_access_policy_name        = "${local.env}-${var.secret_access_policy_name}"
  container_exec_policy_name       = "${local.env}-${var.container_exec_policy_name}"
  container_port                   = var.container_port
  task_name                        = "${local.env}-${var.task_name}"
  task_role_name                   = "${local.env}-${var.task_role_name}"
  task_execution_role_name         = "${local.env}-${var.task_execution_role_name}"
  container_name                   = "${local.env}-${var.container_name}"
  ecr_repo_access_policy_name      = "${local.env}-${var.ecr_repo_access_policy_name}"
  desired_count                    = var.desired_count
  max_capacity                     = var.max_capacity
  scale_in_cooldown                = var.scale_in_cooldown
  scale_out_cooldown               = var.scale_out_cooldown
  scale_target_value               = var.scale_target_value
  secret_name                      = "${local.env}-${var.secret_name}"
  secrets                          = var.secrets
  envs                             = var.envs
  openai_api_key_name              = "${local.env}-${var.openai_api_key_name}"
  openai_endpoints_name            = "${local.env}-${var.openai_endpoints_name}"
  envs_name                        = "${local.env}-${var.envs_name}"
  ecs_scale_down_alarm_description = "${local.env}-${var.ecs_scale_down_alarm_description}"
  ecs_scale_up_alarm_description   = "${local.env}-${var.ecs_scale_up_alarm_description}"
  ecs_alarm_email                  = var.ecs_alarm_email
  ecr_image_repository_arn         = module.ecr.ecr_image_repository_arn
  ecr_image_repository_url         = module.ecr.ecr_image_repository_url
  vpc_id                           = module.load_balancer.vpc_id
  private_subnet_ids               = module.load_balancer.private_subnet_ids
  target_group_arn                 = module.load_balancer.target_group_arn
  alb_sg_id                        = ["${module.load_balancer.alb_sg_id}"]
}

# load_balancer/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.load_balancer.vpc_id
}

output "app_route53_zone_id"{
  description = "The Route 53 Zone ID for the application"
  value       = var.app_route53_zone_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.load_balancer.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.load_balancer.private_subnet_ids
}

output "cognito_user_pool_id" {
  value       = module.cognito_pool.cognito_user_pool_id
  description = "The UserPool ID"
}

output "user_pool_domain" {
  value       = module.cognito_pool.user_pool_domain
  description = "Custom Domain"
}

output "cognito_user_pool_url" {
  value = module.cognito_pool.cognito_user_pool_url
}

output "cognito_user_pool_client_id" {
  value = module.cognito_pool.cognito_user_pool_client_id
}

output "cognito_user_pool_client_secret" {
  value = module.cognito_pool.cognito_user_pool_client_secret
  sensitive = true
}

# Accessing the outputs from the ECS module
output "app_envs_secret_name" {
  description = "The name of the 'envs' secret from the ECS module."
  value       = module.ecs.envs_secret_name
}

output "app_secrets_secret_name" {
  description = "The name of the 'my_secrets' secret from the ECS module."
  value       = module.ecs.my_secrets_secret_name
}

output "app_secrets_secret_arn" {
  description = "The arn of the 'my_secrets' secret from the ECS module."
  value       = module.ecs.my_secrets_secret_arn
}

output "openai_api_key_secret_name" {
  description = "The name of the 'openai_api_key' secret from the ECS module."
  value       = module.ecs.openai_api_key_secret_name
}

output "openai_endpoints_secret_name" {
  description = "The name of the 'openai_endpoints' secret from the ECS module."
  value       = module.ecs.openai_endpoints_secret_name
}

output "openai_endpoints_secret_arn" {
  description = "The arn of the 'openai_endpoints' secret from the ECS module."
  value       = module.ecs.openai_endpoints_secret_arn
}
output "domain_name" {
  value       = "${local.env}-${var.domain_name}"
  description = "The domain name used for the application"
}

output "pandoc_lambda_layer_arn" {
  value = module.lambda_layer.pandoc_lambda_layer_arn
  description = "The ARN for the existing version of the Pandoc Lambda layer."
}

output "ecr_repository_uri" {
  value = module.ecr.ecr_image_repository_url
}

output "ecr_repository_name" {
  value = module.ecr.ecr_image_repository_name
}

output "ecs_service_name" {
  description = "The Name of the ECS service"
  value       = module.ecs.ecs_service_name
}

output "ecs_cluster_name" {
  description = "The ARN of the ECS Cluster"
  value       = module.ecs.ecs_cluster_name
}
