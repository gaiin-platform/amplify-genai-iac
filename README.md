# Please see: https://www.amplifygenai.org

# Authors

Allen Karns, Jules White, Karely Rodriguez, Max Moundas, Ashraf Ben

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

---

## Getting Started with Deployment

This section provides comprehensive instructions for deploying the Amplify GenAI infrastructure from scratch.

### Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with appropriate permissions for:
   - EC2, ECS, ECR (Elastic Container Registry)
   - Application Load Balancer (ALB)
   - Route53 (DNS management)
   - AWS Certificate Manager (ACM)
   - Cognito (user authentication)
   - Secrets Manager
   - IAM (roles and policies)
   - CloudWatch (logging and monitoring)

2. **AWS CLI** configured with valid credentials:
   ```bash
   aws configure
   ```

3. **Terraform** installed (version 1.0 or higher):
   ```bash
   terraform --version
   ```

4. **Route53 Hosted Zone** for your domain already created in AWS

5. **SSL Certificate** in AWS Certificate Manager (ACM) for your domain (must be in us-east-1 region)

### Configuration Setup

#### Step 1: Create Your Configuration File

Copy the template file to create your configuration:

```bash
cd dev
cp terraform.tfvars.template terraform.tfvars
```

#### Step 2: Configure Required Values

Edit `terraform.tfvars` and replace the following **required** placeholders:

**Domain and DNS Configuration:**
- `domain_name`: Your application domain (e.g., `app.example.com`)
- `app_route53_zone_id`: Your Route53 hosted zone ID (see below for how to find this)

**Cognito Configuration:**
- `cognito_domain`: Your Cognito authentication domain (e.g., `auth.example.com`)
- `cognito_route53_zone_id`: Same as `app_route53_zone_id`

**Notifications:**
- `ecs_alarm_email`: Your email address for receiving deployment and scaling notifications

#### Step 3: Find Your Route53 Hosted Zone ID

Use the AWS CLI to find your hosted zone ID:

```bash
aws route53 list-hosted-zones --query "HostedZones[?Name=='example.com.'].Id" --output text
```

Replace `example.com` with your actual domain name. The output will look like: `Z1234567890ABC`

#### Step 4: Verify Your SSL Certificate

Ensure you have a valid SSL certificate in ACM:

```bash
aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='*.example.com'].CertificateArn" --output text
```

The certificate should cover your domain (wildcard certificates like `*.example.com` are recommended).

### Deployment Process

#### Step 1: Initialize Terraform

Navigate to the `dev` directory and initialize Terraform:

```bash
cd dev
terraform init
```

This will download the required Terraform providers and initialize the backend.

#### Step 2: Review the Deployment Plan

Generate and review the execution plan:

```bash
terraform plan
```

Review the output carefully to ensure all resources will be created as expected.

#### Step 3: Deploy the Infrastructure

Apply the Terraform configuration:

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment. This process typically takes 10-15 minutes.

#### Step 4: Export Terraform Outputs

After successful deployment, export the outputs to a JSON file:

```bash
terraform output -json > terraform-outputs.json
```

These outputs contain critical information needed for backend and frontend configuration.

### Configuration Options

The `terraform.tfvars` file supports extensive customization. Key configuration sections include:

#### Network Configuration
- `vpc_cidr`: VPC CIDR block (default: `10.0.0.0/16`)
- `public_subnet_cidrs`: Public subnet CIDR blocks for ALB
- `private_subnet_cidrs`: Private subnet CIDR blocks for ECS tasks

#### ECS Configuration
- `container_cpu`: CPU units for ECS tasks (default: 1024 = 1 vCPU)
- `container_memory`: Memory for ECS tasks in MB (default: 4096 = 4 GB)
- `desired_count`: Initial number of ECS tasks (default: 1)
- `min_capacity`: Minimum tasks for auto-scaling (default: 1)
- `max_capacity`: Maximum tasks for auto-scaling (default: 5)
- `scale_target_value`: Target CPU utilization for scaling (default: 75%)

#### Security Configuration
- `disable_public_signup`: Set to `true` to disable public user registration
- `use_saml_idp`: Set to `true` to enable SAML federation
- `create_pre_auth_lambda`: Set to `true` to use pre-authentication Lambda

For a complete list of configuration options with descriptions, see `terraform.tfvars.example`.

### Post-Deployment Steps

After infrastructure deployment:

1. **Configure Secrets**: Add API keys to AWS Secrets Manager
   - OpenAI API key (if using OpenAI models)
   - Anthropic API key (if using Claude models)
   - NEXTAUTH_SECRET (auto-generated, but can be customized)

2. **Deploy Backend Services**: Deploy Lambda functions using Serverless Framework

3. **Update Environment Variables**: Update frontend environment variables with backend API endpoints

4. **Deploy Frontend**: Build and deploy the Next.js frontend to ECS

For detailed deployment instructions, see `dev/DEPLOYMENT_SETUP.md`.

### Troubleshooting

#### Common Issues and Solutions

**Issue: Route53 Zone Not Found**
- Verify the zone ID is correct using `aws route53 list-hosted-zones`
- Ensure the zone exists in your AWS account
- Check that you're using the correct AWS profile/credentials

**Issue: Certificate Validation Failed**
- Ensure you have a valid certificate in ACM for your domain
- Certificate must be in the `us-east-1` region
- Use a wildcard certificate (e.g., `*.example.com`) to cover subdomains
- Verify certificate status is "Issued" not "Pending Validation"

**Issue: VPC CIDR Conflicts**
- Choose a CIDR range that doesn't conflict with existing VPCs
- Ensure subnet CIDRs are within the VPC CIDR range
- Verify subnet CIDRs don't overlap with each other

**Issue: Terraform State Lock**
- If deployment fails mid-way, Terraform state may be locked
- Wait a few minutes and try again
- If persistent, manually unlock: `terraform force-unlock <LOCK_ID>`

**Issue: Insufficient Permissions**
- Ensure your AWS credentials have permissions for all required services
- Check IAM policies attached to your user/role
- Review CloudTrail logs for permission denied errors

**Issue: Resource Already Exists**
- If resources from a previous deployment exist, either:
  - Import them into Terraform state: `terraform import <resource_type>.<name> <resource_id>`
  - Or destroy them manually and redeploy

### Cleanup and Resource Deletion

To destroy all resources created by Terraform:

```bash
cd dev
terraform destroy
```

**Warning**: This will permanently delete all infrastructure resources. Ensure you have backups of any important data.

### Security Best Practices

1. **Never commit `terraform.tfvars`** to version control
   - The `.gitignore` file is configured to exclude this file
   - Only commit template files (`*.tfvars.template`, `*.tfvars.example`)

2. **Use AWS Secrets Manager** for sensitive values
   - API keys, database passwords, and secrets should never be in Terraform files
   - Reference secrets from Secrets Manager in your application code

3. **Enable MFA** on your AWS account

4. **Use IAM roles** with least-privilege permissions

5. **Regularly rotate** API keys and secrets

6. **Enable CloudTrail** for audit logging

7. **Review security groups** to ensure only necessary ports are open

### Architecture Overview

The infrastructure consists of the following components:

- **VPC**: Isolated network with public and private subnets across multiple availability zones
- **Application Load Balancer (ALB)**: Distributes traffic to ECS tasks with SSL termination
- **ECS Fargate**: Runs containerized Next.js frontend application
- **ECR**: Stores Docker images for the frontend
- **Cognito**: Manages user authentication and authorization
- **Route53**: DNS management and domain routing
- **Secrets Manager**: Securely stores API keys and secrets
- **CloudWatch**: Logging, monitoring, and alarms
- **Auto Scaling**: Automatically scales ECS tasks based on CPU utilization

### Additional Resources

- **Detailed Setup Guide**: See `dev/DEPLOYMENT_SETUP.md` for step-by-step instructions
- **Configuration Template**: See `dev/terraform.tfvars.template` for all available options
- **Configuration Example**: See `dev/terraform.tfvars.example` for detailed field descriptions
- **Module Documentation**: Each module in `modules/` has its own README with specific details

### Support and Contributing

For issues, questions, or contributions:
- Open an issue in the repository
- Review existing documentation in the `docs/` directory
- Check AWS CloudWatch logs for runtime errors
- Consult the Amplify GenAI documentation at https://www.amplifygenai.org

