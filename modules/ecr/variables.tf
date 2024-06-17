variable "ecr_repo_name" {
  description = "The name of the ECR repository"
  type        = string
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

variable "service_name" {
  description = "The name of the ECS service"
  type        = string
}

variable "cluster_name" {
  description = "The name of the ECS service"
  type        = string
  default     = ""
}

variable "notification_arn" {
  description = "SNS Arn for Code Pipeline Notification"
  type        =  string
  default     =  ""
}
