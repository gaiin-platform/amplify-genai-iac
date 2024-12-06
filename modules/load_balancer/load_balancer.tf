# Get a list of all available Availability Zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get Caller Account Identity
data "aws_caller_identity" "current" {}

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
  zone_id         = var.app_route53_zone_id
  records         = [each.value.record]
  ttl             = 60
}

resource "aws_acm_certificate" "ssl_cert" {
  count             = var.root_redirect ? 0:1
  domain_name       = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
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
  zone_id         = var.app_route53_zone_id
  records         = [each.value.record]
  ttl             = 60
}

# Create the VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

# Add these resources after the VPC resource

resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  name = "/aws/vpc-flow-log/${aws_vpc.main.id}"
  retention_in_days = 30
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name = "vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Create public subnets in two different AZs
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# Create private subnets in the same AZs as the public subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "main-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Update the private route table to use the NAT Gateway for internet-bound traffic
resource "aws_route" "private_nat_gw" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Create public route table for the VPC
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Create private route table for the VPC
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-route-table"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  for_each      = { for idx, subnet in aws_subnet.public : idx => subnet }
  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

# Ensure the private route table is associated with the private subnets
resource "aws_route_table_association" "private" {
  for_each      = { for idx, subnet in aws_subnet.private : idx => subnet }
  route_table_id = aws_route_table.private.id
  subnet_id      = each.value.id
}

# Create an S3 gateway endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id
  ]

  policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": ["s3:*"],
        "Resource": ["arn:aws:s3:::*/*"],
        "Condition": {
          "StringEquals": {
            "aws:sourceVpc": "${aws_vpc.main.id}"
          }
        }
      }
    ]
  }
  POLICY
}

resource "aws_security_group" "alb_sg" {
  name        = var.alb_security_group_name
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

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

# Generate a random id
resource "random_id" "random" {
  byte_length = 8
}

# S3 Bucket for storing ALB access logs
resource "aws_s3_bucket" "alb_access_logs" {
  bucket = "${var.alb_logging_bucket_name}-${random_id.random.hex}"
  force_destroy = true

  tags = {
    Name = "alb-access-logs"
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs_policy" {
  bucket = aws_s3_bucket.alb_access_logs.id
  depends_on = [aws_s3_bucket.alb_access_logs]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement =  [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [data.aws_elb_service_account.lb.arn]
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.alb_access_logs.arn}/*"
      
    }
  ]
  })
}

data "aws_elb_service_account" "lb" {}

resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false   
  access_logs {
    bucket  = aws_s3_bucket.alb_access_logs.bucket
    enabled = true
  }

  depends_on = [aws_acm_certificate_validation.ssl_cert_validation, aws_s3_bucket.alb_access_logs]
}

#Create 2 Route53 records if root_redirect is false  CNAME for e.g. alpha.vanderbilt.ai or dev.vanderbilt.ai - Adjusted to Alias because subdomain is delegated. 
resource "aws_route53_record" "root_cname" {
  count = var.root_redirect ? 0:1
  zone_id = var.app_route53_zone_id
  name    = var.domain_name
  type    = "A" 
    
  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true # Set to false if you do not want to evaluate the health of the target
  }
}

#Create 2 Route53 records if root_redirect is true Alias record for root domain and CNAME for www
resource "aws_route53_record" "root_alias" {
  count   = var.root_redirect ? 1 : 0
  zone_id = var.app_route53_zone_id
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
  zone_id = var.app_route53_zone_id
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
  vpc_id   = aws_vpc.main.id
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
