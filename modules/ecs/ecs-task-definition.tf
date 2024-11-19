resource "aws_ecs_task_definition" "app_task" {
  family                   = var.task_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = var.container_name
    image = var.ecr_image_repository_url
    cpu   = var.container_cpu
    memory = var.container_memory 
    portMappings = [
      {
        containerPort = var.container_port
      }
    ]
    secrets = [
      {name      = "AVAILABLE_MODELS"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:AVAILABLE_MODELS::"
      },
      {name      = "AZURE_API_NAME"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:AZURE_API_NAME::"
      },
      {name      = "AZURE_DEPLOYMENT_ID"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:AZURE_DEPLOYMENT_ID::"
      },
      {name      = "API_BASE_URL"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:API_BASE_URL::"
      },
      {name      = "CHAT_ENDPOINT"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:CHAT_ENDPOINT::"
      },
      {name      = "COGNITO_CLIENT_ID"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:COGNITO_CLIENT_ID::"
      },
      {name      = "COGNITO_ISSUER"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:COGNITO_ISSUER::"
      },
      {name      = "DEFAULT_MODEL"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:DEFAULT_MODEL::"
      },
      {name      = "COGNITO_DOMAIN"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:COGNITO_DOMAIN::"
      },
      {name      = "DEFAULT_FUNCTION_CALL_MODEL"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:DEFAULT_FUNCTION_CALL_MODEL::"
      },
      {name      = "COGNITO_CLIENT_SECRET"
        valueFrom = "${aws_secretsmanager_secret.my_secrets.arn}:COGNITO_CLIENT_SECRET::"
      },
      {name      = "MIXPANEL_TOKEN"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:MIXPANEL_TOKEN::"
      },
      {name      = "NEXTAUTH_SECRET"
        valueFrom = "${aws_secretsmanager_secret.my_secrets.arn}:NEXTAUTH_SECRET::"
      },
      {name      = "NEXTAUTH_URL"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:NEXTAUTH_URL::"
      },
      {name      = "OPENAI_API_HOST"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:OPENAI_API_HOST::"
      },
      {name      = "OPENAI_API_KEY"
        valueFrom = "${aws_secretsmanager_secret.my_secrets.arn}:OPENAI_API_KEY::"
      },
      {name      = "OPENAI_API_TYPE"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:OPENAI_API_TYPE::"
      },
      {name      = "OPENAI_API_VERSION"
        valueFrom = "${aws_secretsmanager_secret.envs.arn}:OPENAI_API_VERSION::"
      }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
        awslogs-region        = var.region # Replace with your AWS region
        awslogs-stream-prefix = var.cloudwatch_log_stream_prefix
      }
    }
  }])
}

resource "aws_iam_role" "ecs_execution_role" {
  name = var.task_execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = var.task_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach policies to the task role as necessary

resource "aws_iam_policy" "secret_access_policy" {
  name        = var.secret_access_policy_name
  description = "Policy that grants access to a specific secret in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          // Add other actions as needed.
        ],
        Resource  = [
          aws_secretsmanager_secret.envs.arn,
          aws_secretsmanager_secret.my_secrets.arn,
          aws_secretsmanager_secret.openai_api_key.arn,
          aws_secretsmanager_secret.openai_endpoints.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secret_access_policy.arn
}

resource "aws_iam_policy" "cloudwatch_logs_write_policy" {
  name        = var.cloudwatch_policy_name
  description = "Policy that grants permissions to write to a specific CloudWatch Logs group"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "logs:*"
        ],
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_logs_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_write_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_log_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_write_policy.arn
  
}

resource "aws_iam_policy" "ecr_repo_access_policy" {
  name        = var.ecr_repo_access_policy_name
  description = "Policy that grants access to a specific ECR repository"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetRepositoryPolicy",
          // Include additional actions as needed, e.g., for pushing images:
          // "ecr:PutImage",
          // "ecr:InitiateLayerUpload",
          // "ecr:UploadLayerPart",
          // "ecr:CompleteLayerUpload"
        ],
        Resource  = var.ecr_image_repository_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ecr_repo_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecr_repo_access_policy.arn
}

resource "aws_iam_policy" "container_exec_policy" {
  name        = var.container_exec_policy_name
  description = "Policy that grants permissions to exec into running fargate containers"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "container_exec_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.container_exec_policy.arn
}
