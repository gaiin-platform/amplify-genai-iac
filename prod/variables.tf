#ECR Variables

variable "ecr_repo_name" {
  description = "The name of the ECR repository"
  type        = string
  default     = "your-repo"
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

#ALB Variables

variable "alb_name" {
  description = "The name of the ALB"
  default     = "your-alb"
}

variable "domain_name" {
  description = "name of domain"
  default     = "yourdomain"
}

variable "root_redirect" {
  description = "Whether to create an extra load balancer rule for root of domain. (e.g. site.co, -> www.site.com)"
  type        = bool
  default     = false

}

variable "app_route53_zone_id" {
  description = "The Route53 hosted zone ID for the domain"
}

variable "target_group_name" {
  description = "The name of the target group"
  type        = string
}

variable "target_group_port" {
  description = "The port of the target group"
  type        = string

}

variable "alb_security_group_name" {
  description = "The name of the alb security group"
  type        = string
  default     = "your-security-group-name"

}

variable "cloudwatch_policy_name" {
  description = "The name of the CloudWatch policy"
  type        = string
  default     = "your-cloud-watcy-policy-name"

}

variable "ecr_repo_access_policy_name" {
  description = "The name of the ECR repo access policy"
  type        = string
  default     = "your-ecr-repo-access-policy"

}

variable "container_exec_policy_name" {
  description = "The name of the container exec policy"
  type        = string
  default     = "your-container-exec-policy"

}

variable "secret_access_policy_name" {
  description = "The name of the secret access policy"
  type        = string

}

variable "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  type        = string
  default     = "/ecs/"

}

variable "cloudwatch_log_stream_prefix" {

}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running in the ECS service"
  type        = number
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "The name of the ECS service"
  type        = string
}

variable "container_name" {
  description = "The name of the container within the task"
  type        = string
}
variable "container_port" {
  description = "The port number on the container that is bound to the user-specified or automatically assigned host port"
  type        = number
}
variable "max_capacity" {
  description = "Maximum capacity for Application Auto Scaling"
  type        = number
}

variable "min_capacity" {
  description = "Minimum capacity for Application Auto Scaling"
  type        = number
}

variable "scale_target_value" {
  description = "The target value for the scaling policy"
  type        = number
}

variable "scale_in_cooldown" {
  description = "The amount of time, in seconds, after a scale in activity completes before another scale in activity can start"
  type        = number
}

variable "scale_out_cooldown" {
  description = "The amount of time, in seconds, after a scale out activity completes before another scale out activity can start"
  type        = number
}

variable "secret_name" {
  description = "The name of the secrets container in AWS Secrets Manager"
  type        = string
}
variable "openai_api_key_name" {
  description = "The name of the openai_api_key in AWS Secrets Manager"
  type        = string
}

variable "openai_endpoints_name" {
  description = "The name of the openai endpoints in AWS Secrets Manager"
  type        = string
}

variable "secrets" {
  description = "A map of the secrets to store"
  type        = map(string)
  default = {
    NEXT_PUBLIC_DEFAULT_SYSTEM_PROMPT = ""
    OPENAI_API_KEY                    = ""
    OPENAI_API_HOST                   = ""
    OPENAI_API_TYPE                   = ""
    OPENAI_API_VERSION                = ""
    AZURE_API_NAME                    = ""
    AZURE_DEPLOYMENT_ID               = ""
    AUTH0_AUDIENCE                    = ""
    AUTH0_SCOPE                       = ""
    STATE_API_URL                     = ""
    SHARE_API_URL                     = ""
    COGNITO_CLIENT_ID                 = ""
    COGNITO_CLIENT_SECRET             = ""
    COGNITO_DOMAIN                    = ""
    NEXT_PUBLIC_MIXPANEL_TOKEN        = ""
    AVAILABLE_MODELS                  = ""
    DEFAULT_MODEL                     = ""
    AUTH0_SECRET                      = ""
    AUTH0_BASE_URL                    = ""
    AUTH0_ISSUER_BASE_URL             = ""
    AUTH0_CLIENT_ID                   = ""
    AUTH0_CLIENT_SECRET               = ""
    AUTH0_AUDIENCE                    = ""
    ASSISTANT_API_URL                 = ""
    CONVERT_API_URL                   = ""
    FILE_API_URL                      = ""
    MARKET_API_URL                    = ""
  }
  sensitive = true
}

variable "envs_name" {
  description = "The name of the environment variables container in AWS Secrets Manager"
  type        = string
}

variable "envs" {
  description = "A map of the secrets to store"
  type        = map(string)
  default = {
    NEXT_PUBLIC_DEFAULT_SYSTEM_PROMPT = ""
    OPENAI_API_HOST                   = ""
    OPENAI_API_TYPE                   = ""
    OPENAI_API_VERSION                = ""
    AZURE_API_NAME                    = ""
    AZURE_DEPLOYMENT_ID               = ""
    AUTH0_AUDIENCE                    = ""
    AUTH0_SCOPE                       = ""
    STATE_API_URL                     = ""
    SHARE_API_URL                     = ""
    COGNITO_CLIENT_ID                 = ""
    COGNITO_DOMAIN                    = ""
    NEXT_PUBLIC_MIXPANEL_TOKEN        = ""
    AVAILABLE_MODELS                  = ""
    DEFAULT_MODEL                     = ""
    AUTH0_BASE_URL                    = ""
    AUTH0_ISSUER_BASE_URL             = ""
    AUTH0_CLIENT_ID                   = ""
    AUTH0_CLIENT_SECRET               = ""
  }
  sensitive = true
}

variable "container_cpu" {
  description = "The number of cpu units used by the task"
  type        = number
}

variable "container_memory" {
  description = "The amount (in MiB) of memory used by the task"
  type        = number
}

variable "ecs_alarm_email" {
  description = "The email address to send ECS alarms to"
  type        = string
}

variable "ecs_scale_up_alarm_description" {
  description = "The description for the scale up alarm"
  type        = string
}

variable "ecs_scale_down_alarm_description" {
  description = "The name of the scale up alarm"
  type        = string
}

variable "task_name" {
  description = "The name of the task definition"
  type        = string
}

variable "task_role_name" {
  description = "The name of the task role"
  type        = string
}

variable "task_execution_role_name" {
  description = "The name of the task execution role"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "alb_sg_id" {
  description = "The ID of the security group associated with the ALB"
  type        = list(string)
  default     = [""]
}

variable "cognito_route53_zone_id" {
  description = "The Route53 hosted zone ID for the domain"
}

variable "cognito_domain" {
  description = "Enter a string. Must be alpha numeric 3-63 in length."
  type        = string
}

variable "userpool_name" {
  description = "Enter name for Userpool"
  type        = string
}

variable "provider_name" {
  description = "Enter name for Userpool"
  type        = string
}

variable "sp_metadata_url" {
  description = "Enter the SAML provider metadata file location"
  type        = string
}

variable "callback_urls" {
  description = "Enter Call Back Urls for SSO"
  type        = list(string)
}

variable "logout_urls" {
  description = "Enter Logout Urls for SSO"
  type        = list(string)

}

variable "create_pre_auth_lambda" {
  description = "Boolean for Pre auth lambda creation"
  type        = bool
  default     = false
}

variable "use_saml_idp" {
  description = "Boolean for create SAML IDP on Cognito Pool"
  type        = bool
  default     = false
}

variable "disable_public_signup" {
  description = "Disable Public Signup on Cognito Pool"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)
}

variable "alb_logging_bucket_name" {
  description = "ALB Logging Bucket Name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ECS Deployment"
  type        = string
  default     = ""
}

variable "target_group_arn" {
  description = "Target Group Arn on Loadbalancer"
  type        = string
  default     = ""
}

variable "ecr_image_repository_arn" {
  description = "Arn for ECR Image Repo"
  type        = string
  default     = ""
}

variable "ecr_image_repository_url" {
  description = "URL for ECR Image Repo"
  type        = string
  default     = ""
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "main-vpc"
}
