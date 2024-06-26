# Please see: https://www.amplifygenai.org

# Authors

Allen Karns, Jules White, Karely Rodriguez, Max Moundas

# AWS Infrastructure for Amplify as Terraform Modules

This repository contains very opionated Terraform modules for setting up AWS infrastructure components for a scalable infrastructure to deploy AmplifyGenAI into. The infrastructure includes a load balancer, an ECR repository, and an ECS cluster with Fargate, along with the beginnings of a basic ecr deployment pipeline. It is part of a larger deployment for Amplify GenAI which can be found at https://github.com/gaiin-platform.

## Modules Overview

The Terraform configuration is organized into modules for reusability and manageability:

- **Load Balancer Module**: Sets up an Application Load Balancer (ALB), target groups, and necessary Route 53 records. It also manages SSL certificate creation and validation, VPC and subnet creation, and security group rules.
- **ECR Module**: Creates an ECR for storing Docker images.
- **ECS Module**: Provisions an ECS cluster, task definitions, services, IAM roles, CloudWatch log groups, and Auto Scaling configurations. It also manages task execution roles, task roles, CloudWatch alarms, and Service Auto Scaling policies.
- **Cognito User Pool Module**: Configures a Cognito User Pool for user authentication, along with a user pool client, domain, and identity provider.

## Prerequisites

- An AWS account with the necessary permissions to create the resources described.
- Terraform installed on your local machine.
- AWS CLI configured with access credentials.

## Using the Modules

### Load Balancer Module

To set up the load balancer, include the following module configuration in your Terraform:
#TODO: do we want to mention what file here?

```hcl
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
```

### ECR Module
To create an ECR repository, use the following module configuration:

```hcl
module "ecr" {
  source        = "../modules/ecr"
  ecr_repo_name = "${local.env}-${var.ecr_repo_name}"
  service_name  = module.ecs.ecs_service_name
  cluster_name  = module.ecs.ecs_cluster_name
  notification_arn = module.ecs.ecs_alarm_notifications_topic_arn
}
```

### ECS Module
To provision the ECS cluster and related resources, include the following module configuration:

```hcl
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
```

### Cognito User Pool Module

To configure a Cognito User Pool for user authentication, use the following module configuration:

```hcl
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
```

## Variables

Each module has specific input variables that you need to provide. Refer to the respective module's variables file for the full list of required and optional variables.

## Outputs

Each module will have its own set of outputs that can be used by other modules or for reference. Check the `outputs.tf` file in each module directory for details.

## Applying the Configuration

To apply the Terraform configuration, navigate to the root module where your module configurations are defined and run:

```sh
terraform init
terraform plan
terraform apply
```

## Cleanup

To destroy the resources created by these modules, run:

```sh
terraform destroy
```

## Contributing

If you wish to contribute to this project, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Please replace the placeholder values (e.g., `../modules/load_balancer`, `${local.env}-${var.alb_name}`, etc.) with the actual paths and variable values specific to your environment. The provided module configurations are examples and may need to be adjusted to fit your specific use case.
