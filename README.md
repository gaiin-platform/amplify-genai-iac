# Please see: https://www.amplifygenai.org

# Authors

Allen Karns, Jules White, Karely Rodriguez, Max Moundas

# AWS Infrastructure for Amplify as Terraform Modules

This repository contains Terraform modules for setting up AWS infrastructure components for a scalable and secure web application. The infrastructure includes a load balancer, an ECR repository, and an ECS cluster with Fargate, along with necessary security and monitoring configurations.

## Modules Overview

The Terraform configuration is organized into modules for reusability and manageability:

- **Load Balancer Module**: Sets up an Application Load Balancer (ALB), target groups, and necessary Route 53 records.
- **ECR Module**: Creates an Elastic Container Registry (ECR) for storing Docker images.
- **ECS Module**: Provisions an ECS cluster, task definitions, services, IAM roles, CloudWatch log groups, and Auto Scaling configurations.
- **Cognito User Pool Module**: Configures a Cognito User Pool for user authentication, along with a user pool client, domain, and identity provider.

## Prerequisites

- An AWS account with the necessary permissions to create the resources described.
- Terraform installed on your local machine.
- AWS CLI configured with access credentials.

## Using the Modules

### Load Balancer Module

To set up the load balancer, include the following module configuration in your Terraform:

```hcl
module "load_balancer" {
  source                  = "../modules/load_balancer"
  alb_name                = "${local.env}-${var.alb_name}"
  alb_logging_bucket      = var.alb_logging_bucket
  domain_name             = "${local.env}-${var.domain_name}"
  hosted_zone_id          = var.route53_zone_id
  public_subnet_ids       = var.public_subnet_ids
  target_group_name       = "${local.env}-${var.target_group_name}-${var.target_group_port}"
  target_group_port       = var.target_group_port
  alb_security_group_name = "${local.env}-${var.alb_security_group_name}"
  root_redirect           = false
}
```

### ECR Module

To create an ECR repository, use the following module configuration:

```hcl
module "ecr" {
  source        = "../modules/ecr"
  ecr_repo_name = "${local.env}-${var.ecr_repo_name}"
}
```

### ECS Module

To provision the ECS cluster and related resources, include the following module configuration:

```hcl
module "ecs" {
  source                           = "../modules/ecs"
  depends_on                       = [module.load_balancer]
  cluster_name                     = "${local.env}-${var.cluster_name}"
  // ... (Include all other ECS module variables as shown in the provided example)
}
```

## Cognito User Pool Module

The Cognito User Pool module provisions the following resources:

- **AWS Cognito User Pool**: Manages user accounts and authentication within your application.
- **AWS Cognito User Pool Domain**: Associates a custom domain with the user pool.
- **AWS Cognito User Pool Client**: Configures client settings for the user pool.
- **AWS Route 53 Record**: Sets up a DNS record for the Cognito custom domain.
- **AWS Cognito Identity Provider**: Configures a SAML-based identity provider for the user pool.

### Example Usage

```hcl
module "cognito_user_pool" {
  source = "../modules/cognito_user_pool"

  cognito_domain         = ""
  userpool_name          = ""
  provider_name          = ""
  certificate_arn        = ""
  sp_metadata_url        = ""
  callback_urls          = [""]
  logout_urls            = [""]
  create_pre_auth_lambda = false
  use_saml_idp           = false
  route53_zone_id        = "" # Replace with your Route 53 hosted zone ID
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
