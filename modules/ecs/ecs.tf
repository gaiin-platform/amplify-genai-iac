# main.tf

# Generate a random id
resource "random_id" "random" {
  byte_length = 8
}

# ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS Service
resource "aws_ecs_service" "service" {
  name            = "${var.service_name}-${random_id.random.hex}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count
  health_check_grace_period_seconds = 900

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_controller {
    type = "ECS"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# add scaling based on cloudwatch metrics
resource "aws_appautoscaling_target" "ecs_service" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "scale_up"
  policy_type        = "StepScaling" # Or "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down" {
  name               = "scale_down"
  policy_type        = "StepScaling" # Or "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_sns_topic" "ecs_alarm_notifications" {
  name = "ecs-service-alarms"
}

resource "aws_sns_topic_subscription" "ecs_alarm_email" {
  topic_arn = aws_sns_topic.ecs_alarm_notifications.arn
  protocol  = "email"
  endpoint  = var.ecs_alarm_email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high_cpu_utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = var.ecs_scale_up_alarm_description
  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.service.name
  }
  alarm_actions = [aws_appautoscaling_policy.scale_up.arn, aws_sns_topic.ecs_alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low_cpu_utilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "25"
  alarm_description   = var.ecs_scale_down_alarm_description
  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.service.name
  }
  alarm_actions = [aws_appautoscaling_policy.scale_down.arn, aws_sns_topic.ecs_alarm_notifications.arn]
}

# Security Group for ECS tasks
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.service_name}-ecs-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Ingress rule. Ref alb_sg_id or replace with the correct reference.
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = var.alb_sg_id
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
