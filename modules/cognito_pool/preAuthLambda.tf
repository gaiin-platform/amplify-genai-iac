resource "aws_lambda_function" "pre_auth_trigger" {
  count = var.create_pre_auth_lambda ? 1 : 0

  function_name = "myPreAuthTriggerFunction"
  handler       = "preAuthLambda.lambda_handler" # Replace with the actual handler
  role          = aws_iam_role.lambda_pre_auth_exec_role[0].arn
  runtime       = "python3.10"

  # Define the path to the ZIP file containing your Lambda code
  filename      = "../files/preAuthLambda.zip"

  source_code_hash = filebase64sha256("../files/preAuthLambda.zip")
}

resource "aws_iam_policy" "lambda_cognito_policy" {
  count = var.create_pre_auth_lambda ? 1 : 0  
  name        = "lambda_cognito_policy"
  description = "IAM policy for Lambda function to interact with Cognito and CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:AdminGetUser"
        ],
        Resource = aws_cognito_user_pool.main.arn  # Restrict to the specific Cognito user pool ARN(s)
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"  # Restrict to the specific log group ARN(s) if necessary
      },
    ],
  })
}

resource "aws_iam_role" "lambda_pre_auth_exec_role" {
  count = var.create_pre_auth_lambda ? 1 : 0  
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_cognito_policy_attachment" {
  count = var.create_pre_auth_lambda ? 1 : 0

  role       = aws_iam_role.lambda_pre_auth_exec_role[0].name
  policy_arn = aws_iam_policy.lambda_cognito_policy[0].arn
}

resource "aws_lambda_permission" "allow_cognito_to_invoke_pre_auth" {
  count = var.create_pre_auth_lambda ? 1 : 0

  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_auth_trigger[0].function_name
  principal     = "cognito-idp.amazonaws.com"

  # The source ARN is the ARN of the Cognito user pool that will invoke the Lambda function.
  source_arn    = aws_cognito_user_pool.main.arn
}
