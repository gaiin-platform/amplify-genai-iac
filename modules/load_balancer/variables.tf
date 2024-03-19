variable "vpc_id" {
  description = "The VPC ID where the ALB will be deployed"
}

variable "public_subnet_ids" {
  description = "The list of subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_name" {
  description = "The name of the ALB"
  default     = "my-alb"
}

variable "domain_name" {
  description = ""
  type        = string
}

variable "root_redirect" {
  description = "Whether to create an extra load balancer rule for root of domain. (e.g. vanderbilt.ai -> www.vanderbilt.ai)"
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

variable "target_group_name" {
  description = "The name of the target group for the production environment"
  default     = "gen-ai-tg"
  
}
 variable "target_group_port" {
   description = "The port of the target group"
   type        = string  
   default     = 3000
   
 }

 variable "alb_security_group_name" {
   description = "The name of the security group for the ALB"
   default     = "gen-ai-alb-sg"
   
 }




