#Code pipeline

# Generate a random id
resource "random_id" "random" {
  byte_length = 8
}

# Access logs S3 bucket
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.service_name}-s3-access-logs"
  force_destroy = true
}

# Access logs bucket policy
resource "aws_s3_bucket_policy" "access_logs_policy" {
  bucket = aws_s3_bucket.access_logs.id
  depends_on = [aws_s3_bucket.access_logs] # Ensure the bucket is created first

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.access_logs.arn}/*"
      }
    ]
  })
}

# Block public access for access logs bucket
resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
}

# CodePipeline Artifacts Store
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.service_name}-codepipeline-artifacts"
  force_destroy = true
}

# CodePipeline artifacts bucket policy
resource "aws_s3_bucket_policy" "codepipeline_artifacts_policy" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  depends_on = [aws_s3_bucket.codepipeline_artifacts] # Ensure the bucket is created first

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"  # Adjust this based on your requirements
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
      }
    ]
  })
}

# Block public access for CodePipeline artifacts bucket
resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
}

# Enable access logging for CodePipeline artifacts bucket
resource "aws_s3_bucket_logging" "codepipeline_artifacts_logging" {
  bucket        = aws_s3_bucket.codepipeline_artifacts.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "log/"
}

# CodePipeline Role
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.service_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

# CodePipeline
resource "aws_codepipeline" "ecs_codepipeline" {
  name     = "${var.service_name}-ecs-deployment-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  # CodePipeline stages: Source, Build, Deploy, Approval
  stage {
    name = "Source"
    action {
      name             = "ECR_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        RepositoryName = aws_ecr_repository.app_repository.name
        ImageTag       = "latest" # or specify a different tag as needed
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "Deploy_to_ECS"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      input_artifacts  = ["source_output"] # Use the artifact from the "Source" stage
      version          = "1"
      configuration = {
        ClusterName   = var.cluster_name
        ServiceName   = var.service_name
        FileName      = "imagedefinitions.json" # Assuming "Source" outputs this directly
      }
    }
  }

  stage {
    name = "Approval"
    action {
      name            = "Manual_Approval"
      category        = "Approval"
      owner           = "AWS"
      provider        = "Manual"
      version         = "1"
      configuration = {
        NotificationArn = var.notification_arn
        CustomData      = "Please approve the deployment of the new container image."
      }
    }
  }
}

# IAM policies for the CodePipeline role
resource "aws_iam_policy" "codepipeline_policy" {
  name    = "${var.service_name}-codepipeline-policy"
  policy  = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:RegisterTaskDefinition",
          # ... additional permissions as required
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "s3:Get*",
          "s3:List*",
          # ... additional permissions for S3 as required
        ],
        Resource = "${aws_s3_bucket.codepipeline_artifacts.arn}/*",
        Effect   = "Allow"
      }
      # ... add any other necessary permissions
    ]
  })
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}
