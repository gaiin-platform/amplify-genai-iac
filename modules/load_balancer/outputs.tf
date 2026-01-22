# load_balancer/outputs.tf

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

# ALB Outputs
output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.alb.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.alb.zone_id
}

output "alb_security_group_id" {
  description = "The security group ID of the Application Load Balancer"
  value       = aws_security_group.alb_sg.id
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.tg.arn
}

# Route53 Outputs
output "route53_record_fqdn" {
  description = "The FQDN of the Route53 record pointing to the ALB"
  value       = var.root_redirect ? aws_route53_record.root_alias[0].fqdn : aws_route53_record.www_cname[0].fqdn
}

# SSL Certificate Outputs
output "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate"
  value       = var.root_redirect ? aws_acm_certificate.ssl_san_cert[0].arn : aws_acm_certificate.ssl_cert[0].arn
}

# Legacy outputs for backward compatibility
output "load_balancer_arn" {
  description = "(Deprecated: use alb_arn) The ARN of the load balancer"
  value       = aws_lb.alb.arn
}

output "alb_sg_id" {
  description = "(Deprecated: use alb_security_group_id) The security group ID of the ALB"
  value       = aws_security_group.alb_sg.id
}
