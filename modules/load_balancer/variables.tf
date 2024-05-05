

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


variable "route53_zone_id" {
  description = "The Route53 hosted zone ID for the domain"
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




