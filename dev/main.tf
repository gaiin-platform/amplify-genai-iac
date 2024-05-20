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
  envs_name                        = "${local.env}-${var.envs_name}"
  ecs_scale_down_alarm_description = "${local.env}-${var.ecs_scale_down_alarm_description}"
  ecs_scale_up_alarm_description   = "${local.env}-${var.ecs_scale_up_alarm_description}"
  ecs_alarm_email                  = "amplify+innovation@vanderbilt.edu"
  ecr_image_repository_arn         = module.ecr.ecr_image_repository_arn
  ecr_image_repository_url         = module.ecr.ecr_image_repository_url
  vpc_id                           = module.load_balancer.vpc_id
  private_subnet_ids               = module.load_balancer.private_subnet_ids
  target_group_arn                 = module.load_balancer.target_group_arn
  alb_sg_id                        = ["${module.load_balancer.alb_sg_id}"]

}













