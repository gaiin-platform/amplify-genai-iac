
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
variable "vpc_id" {
  description = "The VPC ID where the ALB will be deployed"
}

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

variable "hosted_zone_id" {
  description = "The Route53 hosted zone ID for the domain"
}

variable "alb_logging_bucket" {
  description = "ALB Access Log Bucket"
  type        = string
}

variable "public_subnet_ids" {
  description = "The list of subnet IDs for the ALB"
  type        = list(string)

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

variable "subnet_ids" {
  description = "The subnet IDs to launch resources in"
  type        = list(string)
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

variable "tg_arn" {
  description = "The ARN of the target group with which to register targets"
  type        = string
}

variable "secret_name" {
  description = "The name of the secrets container in AWS Secrets Manager"
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

variable "env_vars_name" {
  description = "The name of the environment variables container in AWS Secrets Manager"
  type        = string

}
variable "env_vars" {
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
  type        = string
  default     = ""

}

variable "cognito_domain_module_var" {
  description = "Enter a string. Must be alpha numeric 3-63 in length."
  type        = string
}

variable "userpool_name_module_var" {
  description = "Enter name for Userpool"
  type        = string
}

variable "provider_name_module_var" {
  description = "Enter name for Userpool"
  type        = string
}

variable "certificate_arn_module_var" {
  description = "Enter the Certificate arn used for Cognito Domain"
  type        = string
}

variable "sp_metadata_url_module_var" {
  description = "Enter the SAML provider metadata file location"
  type        = string
}

variable "callback_urls_module_var" {
  description = "Enter Call Back Urls for SSO"
  type        = list(string)
}

variable "logout_urls_module_var" {
  description = "Enter Logout Urls for SSO"
  type        = list(string)

}









