
# ZIP for the authorizer js file
data "archive_file" "authorizer_zip" {
  type        = "zip"
  output_path = "${path.module}/authorizer.zip"

  source {
    filename = "index.js"
    content  = file("${path.module}/authorizer.js")
  }
}

locals {
  authorizer_file_path   = data.archive_file.authorizer_zip.output_path
  authorizer_source_hash = data.archive_file.authorizer_zip.output_base64sha256
}

# Always attach basic execution for CloudWatch Logging
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Deploy the Lambda
resource "aws_lambda_function" "authorizer" {
  filename         = local.authorizer_file_path
  function_name    = "docbox-authorizer-lambda"
  role             = aws_iam_role.lambda_exec.arn
  architectures    = [var.architecture]
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  source_code_hash = local.authorizer_source_hash

  timeout     = 60
  memory_size = 256

  environment {
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    local_sensitive_file.downloaded_zip
  ]
}
