terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.54.0"
    }
  }

  required_version = ">= 1.2.0"

  # Use an AWS S3 bucket to store and manage the terraform state
  backend "s3" {}
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

data "aws_caller_identity" "current" {}

# ZIP for the authorizer js file
data "archive_file" "authorizer_zip" {
  type        = "zip"
  output_path = "${path.module}/authorizer.zip"

  source {
    filename = "index.js"
    content  = file("authorizer.js")
  }
}

# Lambda for docbox HTTP API
module "authorizer_lambda" {
  architecture  = var.architecture
  source        = "./modules/zip_lambda"
  zip_source    = data.archive_file.authorizer_zip.output_path
  function_name = "docbox-authorizer-lambda"
  timeout       = 60
  memory_size   = 256
  handler       = "index.handler"
  runtime       = "nodejs22.x"
}

# Base docbox infra
module "serverless_docbox" {
  source       = "./modules/serverless_docbox"
  aws_profile  = var.aws_profile
  aws_region   = var.aws_region
  architecture = var.architecture
  environment_variables = {
    DOCBOX_DB_HOST              = aws_db_instance.postgres.address
    DOCBOX_DB_PORT              = tostring(aws_db_instance.postgres.port)
    DOCBOX_DB_ROOT_IAM          = "true"
    DOCBOX_SEARCH_INDEX_FACTORY = "database"
  }
  policy_arns = [
    # Provide database access
    aws_iam_policy.docbox_iam_rds_policy.arn
  ]
  use_local_zip = var.use_local_zip
}

# Serverless API gateway into docbox combined with the user defined authorizer
module "serverless_docbox_api" {
  source = "./modules/serverless_docbox_api"

  http_lambda_function_name                 = module.serverless_docbox.http_lambda_function_name
  http_lambda_response_streaming_invoke_arn = module.serverless_docbox.http_lambda_response_streaming_invoke_arn

  authorizer_lambda_function_name = module.authorizer_lambda.function_name
  authorizer_lambda_invoke_arn    = module.authorizer_lambda.function_invoke_arn
}
