# Archive to create from the bootstrap
data "archive_file" "zip" {
  type        = "zip"
  output_path = "${path.module}/${var.function_name}.zip"
  source_file = var.bootstrap_path
}

# Generate an execution role unique to this module instance
resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Always attach basic execution for CloudWatch Logging
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach any special case policies (like SQS execution for the upload worker)
resource "aws_iam_role_policy_attachment" "additional" {
  count      = length(var.additional_policy_arns)
  role       = aws_iam_role.lambda_exec.name
  policy_arn = var.additional_policy_arns[count.index]
}

# Deploy the Lambda
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.zip.output_path
  function_name    = var.function_name
  role             = aws_iam_role.lambda_exec.arn
  architectures    = [var.architecture]
  runtime          = "provided.al2023"
  handler          = "bootstrap"
  source_code_hash = data.archive_file.zip.output_base64sha256

  timeout     = var.timeout
  memory_size = var.memory_size

  environment {
    variables = var.environment_variables
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    data.archive_file.zip
  ]
}
