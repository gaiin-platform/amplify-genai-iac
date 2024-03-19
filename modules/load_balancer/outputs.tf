# load_balancer_module/outputs.tf

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