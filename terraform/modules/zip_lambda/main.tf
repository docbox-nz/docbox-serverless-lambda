locals {
  is_url        = length(regexall("^https?://", var.zip_source)) > 0
  zip_suffix    = local.is_url ? "remote" : "local"
  download_path = "${path.module}/${var.function_name}-${local.zip_suffix}.zip"
}

data "http" "lambda_zip" {
  count = local.is_url ? 1 : 0
  url   = var.zip_source
}

resource "local_sensitive_file" "downloaded_zip" {
  count          = local.is_url ? 1 : 0
  content_base64 = data.http.lambda_zip[0].response_body_base64
  filename       = local.download_path
}

locals {
  lambda_file_path   = local.is_url ? local.download_path : var.zip_source
  lambda_source_hash = local.is_url ? base64sha256(data.http.lambda_zip[0].response_body_base64) : filebase64sha256(var.zip_source)
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
  filename         = local.lambda_file_path
  function_name    = var.function_name
  role             = aws_iam_role.lambda_exec.arn
  architectures    = [var.architecture]
  runtime          = var.runtime
  handler          = var.handler
  source_code_hash = local.lambda_source_hash

  timeout     = var.timeout
  memory_size = var.memory_size

  environment {
    variables = var.environment_variables
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    local_sensitive_file.downloaded_zip
  ]
}
