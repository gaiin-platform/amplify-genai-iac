# variables.tf
variable "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  type        = string
  
}

variable "cloudwatch_log_stream_prefix" {
  description = "The name of the CloudWatch log stream prefix"
  type        = string
  
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

variable "cloudwatch_policy_name" {
  description = "The name of the CloudWatch policy"
  type        = string
}

variable "secret_access_policy_name" {
  description = "The name of the secret access policy"
  type        = string
  
}

variable "container_exec_policy_name" {
  description = "The name of the container exec policy"
  type        = string
  
}

variable "ecr_repo_access_policy_name" {
  description = "The name of the ECR repo access policy"
  type        = string
  
}

variable "subnet_ids" {
  description = "The subnet IDs to launch resources in"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC"
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
variable "public_ip" {
  description = "Whether the task should be assigned a public IP address"
  type        = bool
  default     = true
  
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
variable "tg_arn" {
  description = "The ARN of the target group with which to register targets"
  type        = string
}

variable "alb_sg_id" {
  description = "The security group ID of the Application Load Balancer"
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
  
    OPENAI_API_KEY                    = ""
    COGNITO_CLIENT_SECRET             = ""
    NEXTAUTH_SECRET                   = ""
  }
  sensitive   = true
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
    sensitive   = true
  }

variable "container_cpu" {
  description = "The number of cpu units used by the task"
  type        = number
}

variable "container_memory" {
  description = "The amount (in MiB) of memory used by the task"
  type        = number
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

variable "ecr_image_repository_url" {
  description = "The URL of the ECR image repository"
  type        = string
  
}

variable "ecr_image_repository_arn" {
  description = "The ARN of the ECR image repository"
  type        = string
  
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"

}


