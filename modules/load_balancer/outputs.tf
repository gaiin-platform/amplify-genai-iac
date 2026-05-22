# load_balancer/outputs.tf

output "load_balancer_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.alb.arn
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.tg.arn
}

output "alb_sg_id" {
  description = "The security group ID of the Application Load Balancer"
  value       = aws_security_group.alb_sg.id
}

output "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate"
  value       = local.resolved_ssl_certificate_arn
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.resolved_vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = local.use_existing_vpc ? data.aws_vpc.existing[0].cidr_block : aws_vpc.main[0].cidr_block
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = local.resolved_public_subnet_ids
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = local.resolved_private_subnet_ids
}

output "alb_dns_name" {
  description = "The DNS name of the ALB (use this for external DNS CNAME)"
  value       = aws_lb.alb.dns_name
}
