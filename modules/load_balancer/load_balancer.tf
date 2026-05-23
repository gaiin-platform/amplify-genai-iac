# Get a list of all available Availability Zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get Caller Account Identity
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Locals: resolve VPC ID, subnet IDs, and SSL cert ARN
# ---------------------------------------------------------------------------
locals {
  use_existing_vpc     = var.vpc_id != ""
  use_existing_subnets = length(var.public_subnet_ids) > 0
  use_existing_cert    = var.ssl_certificate_arn != ""
  use_route53          = var.app_route53_zone_id != ""

  resolved_vpc_id = local.use_existing_vpc ? var.vpc_id : aws_vpc.main[0].id
  resolved_ssl_certificate_arn = local.use_existing_cert ? var.ssl_certificate_arn : (
    var.root_redirect ? aws_acm_certificate.ssl_san_cert[0].arn : aws_acm_certificate.ssl_cert[0].arn
  )
  resolved_public_subnet_ids  = local.use_existing_subnets ? var.public_subnet_ids : aws_subnet.public[*].id
  resolved_private_subnet_ids = local.use_existing_subnets ? var.private_subnet_ids : aws_subnet.private[*].id
}

# ---------------------------------------------------------------------------
# ACM Certificate (only created when ssl_certificate_arn is NOT provided)
# ---------------------------------------------------------------------------
resource "aws_acm_certificate" "ssl_san_cert" {
  count                     = !local.use_existing_cert && var.root_redirect ? 1 : 0
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "ssl_san_cert_validation" {
  count                   = !local.use_existing_cert && var.root_redirect && local.use_route53 ? 1 : 0
  certificate_arn         = aws_acm_certificate.ssl_san_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.san_cert_validation : record.fqdn]
}

locals {
  san_cert_validation_records = !local.use_existing_cert && var.root_redirect ? {
    for dvo in aws_acm_certificate.ssl_san_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}
}

resource "aws_route53_record" "san_cert_validation" {
  for_each        = local.use_route53 ? local.san_cert_validation_records : {}
  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.app_route53_zone_id
  records         = [each.value.record]
  ttl             = 60
}

resource "aws_acm_certificate" "ssl_cert" {
  count                     = !local.use_existing_cert && !var.root_redirect ? 1 : 0
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "ssl_cert_validation" {
  count                   = !local.use_existing_cert && !var.root_redirect && local.use_route53 ? 1 : 0
  certificate_arn         = aws_acm_certificate.ssl_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

locals {
  cert_validation_records = !local.use_existing_cert && !var.root_redirect ? {
    for dvo in aws_acm_certificate.ssl_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}
}

resource "aws_route53_record" "cert_validation" {
  for_each = local.use_route53 ? local.cert_validation_records : {}

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.app_route53_zone_id
  records         = [each.value.record]
  ttl             = 60
}

# ---------------------------------------------------------------------------
# VPC (only created when vpc_id is NOT provided)
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  count                = local.use_existing_vpc ? 0 : 1
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

# Data source for existing VPC
data "aws_vpc" "existing" {
  count = local.use_existing_vpc ? 1 : 0
  id    = var.vpc_id
}

# VPC Flow Logs (only for new VPCs)
resource "aws_flow_log" "vpc_flow_log" {
  count           = local.use_existing_vpc ? 0 : 1
  iam_role_arn    = aws_iam_role.vpc_flow_log_role[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log_group[0].arn
  traffic_type    = "ALL"
  vpc_id          = local.resolved_vpc_id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  count             = local.use_existing_vpc ? 0 : 1
  name              = "/aws/vpc-flow-log/${local.resolved_vpc_id}"
  retention_in_days = 30
}

resource "aws_iam_role" "vpc_flow_log_role" {
  count = local.use_existing_vpc ? 0 : 1
  name  = "vpc-flow-log-role-${random_id.random.hex}"
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
  count = local.use_existing_vpc ? 0 : 1
  name  = "vpc-flow-log-policy"
  role  = aws_iam_role.vpc_flow_log_role[0].id

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
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Subnets (only created when existing subnet IDs are NOT provided)
# ---------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = local.use_existing_subnets ? 0 : length(var.public_subnet_cidrs)
  vpc_id                  = local.resolved_vpc_id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = local.use_existing_subnets ? 0 : length(var.private_subnet_cidrs)
  vpc_id            = local.resolved_vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# ---------------------------------------------------------------------------
# Networking: IGW, NAT, Route Tables
# ---------------------------------------------------------------------------

# IGW (only for new subnets — existing VPC already has one)
resource "aws_internet_gateway" "igw" {
  count  = local.use_existing_subnets ? 0 : 1
  vpc_id = local.resolved_vpc_id

  tags = {
    Name = "main-igw"
  }
}

# NAT Gateway - created when create_nat_gateway is true
resource "aws_eip" "nat" {
  count  = var.create_nat_gateway ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  count         = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = local.resolved_public_subnet_ids[0]

  tags = {
    Name = "amplify-nat-gw"
  }
}

# For existing subnets: look up the route tables associated with private subnets
data "aws_route_table" "existing_private" {
  count     = local.use_existing_subnets && var.create_nat_gateway ? length(var.private_subnet_ids) : 0
  subnet_id = var.private_subnet_ids[count.index]
}

# Deduplicate route table IDs (multiple subnets may share the same route table)
locals {
  existing_private_route_table_ids = local.use_existing_subnets && var.create_nat_gateway ? toset(distinct([
    for rt in data.aws_route_table.existing_private : rt.id
  ])) : toset([])
}

# Add NAT Gateway route to existing private route tables (deduplicated)
resource "aws_route" "existing_private_nat_gw" {
  for_each               = local.existing_private_route_table_ids
  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[0].id
}

# For new subnets: add NAT Gateway route to the new private route table
resource "aws_route" "private_nat_gw" {
  count                  = !local.use_existing_subnets && var.create_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[0].id
}

# Route tables (only for new subnets)
resource "aws_route_table" "public" {
  count  = local.use_existing_subnets ? 0 : 1
  vpc_id = local.resolved_vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private" {
  count  = local.use_existing_subnets ? 0 : 1
  vpc_id = local.resolved_vpc_id
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = local.use_existing_subnets ? {} : { for idx, subnet in aws_subnet.public : idx => subnet }
  route_table_id = aws_route_table.public[0].id
  subnet_id      = each.value.id
}

resource "aws_route_table_association" "private" {
  for_each       = local.use_existing_subnets ? {} : { for idx, subnet in aws_subnet.private : idx => subnet }
  route_table_id = aws_route_table.private[0].id
  subnet_id      = each.value.id
}

# S3 Gateway Endpoint (only for new networking)
resource "aws_vpc_endpoint" "s3" {
  count             = local.use_existing_subnets ? 0 : 1
  vpc_id            = local.resolved_vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public[0].id,
    aws_route_table.private[0].id
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
            "aws:sourceVpc": "${local.resolved_vpc_id}"
          }
        }
      }
    ]
  }
  POLICY
}

# ---------------------------------------------------------------------------
# ALB Security Group and Load Balancer
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = var.alb_security_group_name
  description = "Security group for ALB"
  vpc_id      = local.resolved_vpc_id

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
  bucket        = "${var.alb_logging_bucket_name}-${random_id.random.hex}"
  force_destroy = true

  tags = {
    Name = "alb-access-logs"
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs_policy" {
  bucket     = aws_s3_bucket.alb_access_logs.id
  depends_on = [aws_s3_bucket.alb_access_logs]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [data.aws_elb_service_account.lb.arn]
        },
        "Action" : "s3:PutObject",
        "Resource" : "${aws_s3_bucket.alb_access_logs.arn}/*"
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
  subnets            = local.resolved_public_subnet_ids

  enable_deletion_protection = false
  access_logs {
    bucket  = aws_s3_bucket.alb_access_logs.bucket
    enabled = true
  }

  depends_on = [aws_s3_bucket.alb_access_logs]
}

# ---------------------------------------------------------------------------
# Route53 records for ALB (only when using Route53)
# ---------------------------------------------------------------------------
resource "aws_route53_record" "root_cname" {
  count   = local.use_route53 && !var.root_redirect ? 1 : 0
  zone_id = var.app_route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "root_alias" {
  count   = local.use_route53 && var.root_redirect ? 1 : 0
  zone_id = var.app_route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_cname" {
  count   = local.use_route53 && var.root_redirect ? 1 : 0
  zone_id = var.app_route53_zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.alb.dns_name]
}

# ---------------------------------------------------------------------------
# ALB Listeners
# ---------------------------------------------------------------------------
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
  count             = var.root_redirect ? 0 : 1
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = local.resolved_ssl_certificate_arn
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
  count             = var.root_redirect ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = local.resolved_ssl_certificate_arn
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
  name        = var.target_group_name
  port        = var.target_group_port
  protocol    = "HTTP"
  vpc_id      = local.resolved_vpc_id
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

#Create LB Rule if root_redirect is false --non-prod environments
resource "aws_lb_listener_rule" "rule" {
  count        = var.root_redirect ? 0 : 1
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

#Create 2 LB Rules if root_redirect is true --prod environments
resource "aws_lb_listener_rule" "redirect_rule" {
  count        = var.root_redirect ? 1 : 0
  listener_arn = aws_lb_listener.https_root_redirect[0].arn
  action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = "www.${var.domain_name}"
    }
  }
  condition {
    host_header {
      values = [var.domain_name]
    }
  }
}

resource "aws_lb_listener_rule" "www_rule" {
  count        = var.root_redirect ? 1 : 0
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
