module "load_balancer" {
  source                  = "../modules/load_balancer"
  alb_name                = "${local.env}-${var.alb_name}"
  alb_logging_bucket      = var.alb_logging_bucket
  domain_name             = "${var.domain_name}"
  hosted_zone_id          = var.hosted_zone_id
  vpc_id                  = var.vpc_id
  public_subnet_ids       = var.public_subnet_ids
  target_group_name       = "${local.env}-${var.target_group_name}-${var.target_group_port}"
  target_group_port       = var.target_group_port
  alb_security_group_name = "${local.env}-${var.alb_security_group_name}"
  root_redirect           = true
}

module "ecr" {
  source        = "../modules/ecr"
  ecr_repo_name = "${local.env}-${var.ecr_repo_name}"
}

module "ecs" {
  source                       = "../modules/ecs"
  depends_on                   = [module.load_balancer]
  cluster_name                 = "${local.env}-${var.cluster_name}"
  container_cpu                = var.container_cpu
  container_memory             = var.container_memory
  service_name                 = "${local.env}-${var.service_name}"
  vpc_id                       = var.vpc_id
  min_capacity                 = var.min_capacity
  cloudwatch_log_group_name    = "${local.env}-${var.cloudwatch_log_group_name}"
  cloudwatch_log_stream_prefix = var.cloudwatch_log_stream_prefix
  cloudwatch_policy_name       = "${local.env}-${var.cloudwatch_policy_name}"
  secret_access_policy_name    = "${local.env}-${var.secret_access_policy_name}"
  container_exec_policy_name   = "${local.env}-${var.container_exec_policy_name}"
  container_port               = var.container_port
  task_name                    = "${local.env}-${var.task_name}"
  subnet_ids                   = var.subnet_ids
  tg_arn                       = module.load_balancer.target_group_arn
  task_role_name               = "${local.env}-${var.task_role_name}"
  task_execution_role_name     = "${local.env}-${var.task_execution_role_name}"
  container_name               = "${local.env}-${var.container_name}"
  ecr_repo_access_policy_name  = "${local.env}-${var.ecr_repo_access_policy_name}"
  alb_sg_id                    = module.load_balancer.alb_sg_id
  desired_count                = var.desired_count
  max_capacity                 = var.max_capacity
  scale_in_cooldown            = var.scale_in_cooldown
  scale_out_cooldown           = var.scale_out_cooldown
  scale_target_value           = var.scale_target_value
  secret_name                  = "${local.env}-${var.secret_name}"
  secrets                      = var.secrets
  ecr_image_repository_url     = "${module.ecr.ecr_image_repository_url}:latest"
  ecr_image_repository_arn     = module.ecr.ecr_image_repository_arn
  envs                     = var.envs
  envs_name                = "${local.env}-${var.envs_name}"
  ecs_scale_down_alarm_description = "${local.env}-${var.ecs_scale_down_alarm_description}"
  ecs_scale_up_alarm_description = "${local.env}-${var.ecs_scale_up_alarm_description}"
  ecs_alarm_email              = "amplify+prod@vanderbilt.edu"


}

module "cognito_pool" {
  source                     = "../../modules/cognito_pool"
  cognito_domain_module  = "${local.env}-${var.cognito_domain_module}"
  userpool_name_module   = "${local.env}-${var.userpool_name_module}"
  provider_name_module   = var.provider_name_module
  certificate_arn_module = var.certificate_arn_module
  sp_metadata_url_module = var.sp_metadata_url_module
  callback_urls_module   = ["https://${local.env}-ecs.vanderbilt.ai/auth/callback/cognito", "http://localhost:3000/auth/callback/cognito"]
  logout_urls_module     = ["https://${local.env}-ecs.vanderbilt.ai/signout", "http://localhost:3000/signout"]
}











