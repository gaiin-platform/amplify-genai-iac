



resource "aws_acm_certificate" "ssl_san_cert" {
  count             = var.root_redirect ? 1:0
  domain_name       = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "ssl_san_cert_validation" {
  count             = var.root_redirect ? 1:0
  certificate_arn         = aws_acm_certificate.ssl_san_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.san_cert_validation : record.fqdn]
}

locals {
  # Create an empty map or a map of domain validation options based on the condition
  san_cert_validation_records = var.root_redirect ? {
    for dvo in aws_acm_certificate.ssl_san_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}
}
resource "aws_route53_record" "san_cert_validation" {
  # Use for_each to iterate over the local variable
  for_each = local.san_cert_validation_records
  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.hosted_zone_id
  records         = [each.value.record]
  ttl             = 60
}

resource "aws_acm_certificate" "ssl_cert" {
  count             = var.root_redirect ? 0:1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_acm_certificate_validation" "ssl_cert_validation" {
  count                 = var.root_redirect ? 0:1
  certificate_arn         = aws_acm_certificate.ssl_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

locals {
  # Create an empty map or a map of domain validation options based on the condition
  cert_validation_records = !var.root_redirect ? {
    for dvo in aws_acm_certificate.ssl_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}
}

resource "aws_route53_record" "cert_validation" {
  # Use for_each to iterate over the local variable
  for_each = local.cert_validation_records

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.hosted_zone_id
  records         = [each.value.record]
  ttl             = 60
}
resource "aws_security_group" "alb_sg" {
  name        = var.alb_security_group_name
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}


resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  access_logs {
    bucket  = var.alb_logging_bucket
    enabled = true
  }

  depends_on = [aws_acm_certificate_validation.ssl_cert_validation]
}

#Create 2 Route53 records if root_redirect is false  CNAME for e.g. alpha.vanderbilt.ai or dev.vanderbilt.ai
resource "aws_route53_record" "root_cname" {
  count = var.root_redirect ? 0:1
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.alb.dns_name]
}

#Create 2 Route53 records if root_redirect is true Alias record for root domain and CNAME for www
resource "aws_route53_record" "root_alias" {
  count   = var.root_redirect ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A" # Alias records for root domain should be type "A" or "AAAA" (for IPv6)

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true # Set to false if you do not want to evaluate the health of the target
  }
}

resource "aws_route53_record" "www_cname" {
  count = var.root_redirect ? 1:0
  zone_id = var.hosted_zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.alb.dns_name]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.root_redirect ? 0:1
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = aws_acm_certificate.ssl_cert[0].arn
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "You've reached the end"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "https_root_redirect" {
  count             = var.root_redirect ? 1:0
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = aws_acm_certificate.ssl_san_cert[0].arn
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "You've reached the end"
      status_code  = "200"
    }
  }
}



resource "aws_lb_target_group" "tg" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/" # Change this if your app has a different health check endpoint
    port                = var.target_group_port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200,301" # Adjust if your app returns a different success code
  }

  lifecycle {
    create_before_destroy = true
  }
}

#Create LB Rule if root_redirect is false --non-prod environments e.g. alpha.vanderbilt.ai
resource "aws_lb_listener_rule" "rule" {
  count = var.root_redirect ? 0:1
  listener_arn = aws_lb_listener.https[0].arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }
}

#Create 2 LB Rules if root_redirect is true --prod environments e.g. vanderbilt.ai --> www.vanderbilt.ai
resource "aws_lb_listener_rule" "redirect_rule" {
  count = var.root_redirect ? 1:0
  listener_arn = aws_lb_listener.https_root_redirect[0].arn
  action {
    type             = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host       = "www.${var.domain_name}"
    }
  }
  condition {
    host_header {
      values = [var.domain_name]
    }
  }
}

resource "aws_lb_listener_rule" "www_rule" {
  count = var.root_redirect ? 1:0
  listener_arn = aws_lb_listener.https_root_redirect[0].arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = ["www.${var.domain_name}"]
    }
  }
}

