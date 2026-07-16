locals {
  serverless_repo     = "docbox-nz/docbox-serverless-lambda"
  serverless_version  = "0.0.2"
  serverless_base_url = "https://github.com/${local.serverless_repo}/releases/download/${local.serverless_version}"
  serverless_zip_arch = var.architecture == "x86_64" ? "amd64" : "arm64"

  shared_environment_variables = {
    RUST_LOG                    = "debug,docbox_core::notifications::sqs=info"
    DOCBOX_DB_HOST              = aws_db_instance.postgres.address
    DOCBOX_DB_PORT              = tostring(aws_db_instance.postgres.port)
    DOCBOX_DB_ROOT_IAM          = "true"
    DOCBOX_SEARCH_INDEX_FACTORY = "database"
  }
}

# Lambda for performing office file conversion
module "office_converter_lambda" {
  aws_profile  = var.aws_profile
  aws_region   = var.aws_region
  architecture = var.architecture
  source       = "./modules/office_converter_lambda"
}

# # Lambda for docbox HTTP API
# module "http_lambda" {
#   architecture          = var.architecture
#   source                = "./modules/remote_zip_lambda"
#   function_name         = "docbox-http-lambda"
#   download_url          = "${local.serverless_base_url}/docbox-http-lambda-${local.serverless_zip_arch}.zip"
#   timeout               = 60
#   memory_size           = 512
#   environment_variables = local.shared_environment_variables
#   additional_policy_arns = [
#     # Provide access to S3 storage for docbox-* buckets
#     aws_iam_policy.docbox_s3_access_policy.arn,
#     # Provide database access
#     aws_iam_policy.docbox_iam_rds_policy.arn
#   ]
# }

# # Lambda for the automated presigned database&s3 cleanup task
# # TODO: Connect to event schedule
# module "presigned_cleanup_lambda" {
#   architecture          = var.architecture
#   source                = "./modules/remote_zip_lambda"
#   function_name         = "docbox-presigned-cleanup-lambda"
#   download_url          = "${local.serverless_base_url}/docbox-presigned-cleanup-lambda-${local.serverless_zip_arch}.zip"
#   timeout               = 60
#   memory_size           = 256
#   environment_variables = local.shared_environment_variables
#   additional_policy_arns = [
#     # Provide access to S3 storage for docbox-* buckets
#     aws_iam_policy.docbox_s3_access_policy.arn,
#     # Provide database access
#     aws_iam_policy.docbox_iam_rds_policy.arn,
#     # TODO: Policy to allow execution via event
#   ]
# }

# # Lambda for handling file processing on upload completion
# module "upload_completion_lambda" {
#   architecture  = var.architecture
#   source        = "./modules/remote_zip_lambda"
#   function_name = "docbox-upload-completion-lambda"
#   download_url  = "${local.serverless_base_url}/docbox-upload-completion-lambda-${local.serverless_zip_arch}.zip"
#   timeout       = 900
#   memory_size   = 2048
#   environment_variables = merge(local.shared_environment_variables, {
#     DOCBOX_OFFICE_CONVERTER             = "lambda"
#     DOCBOX_CONVERT_LAMBDA_TMP_BUCKET    = module.office_converter_lambda.bucket
#     DOCBOX_CONVERT_LAMBDA_FUNCTION_NAME = module.office_converter_lambda.function_name
#   })

#   additional_policy_arns = [
#     # We need to attach the SQS Queue Execution role so that SQS can trigger this
#     # lambda based on S3 events
#     "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
#     # Provide access the office converter temporary S3 bucket
#     module.office_converter_lambda.s3_access_policy_arn,
#     # Provide invoke access to the office converter lambda
#     module.office_converter_lambda.invoke_policy_arn
#   ]
# }


# Lambda for docbox HTTP API
module "http_lambda" {
  architecture   = var.architecture
  source         = "./modules/local_zip_lambda"
  function_name  = "docbox-http-lambda"
  bootstrap_path = "${path.module}/../target/lambda/docbox-http-lambda/bootstrap"
  timeout        = 60
  memory_size    = 512
  environment_variables = merge(local.shared_environment_variables, {
    AWS_LAMBDA_HTTP_IGNORE_STAGE_IN_PATH = "true",
    LOCAL_DEVELOPMENT                    = "true",
  })
  additional_policy_arns = [
    # Provide access to S3 storage for docbox-* buckets
    aws_iam_policy.docbox_s3_access_policy.arn,
    # Provide database access
    aws_iam_policy.docbox_iam_rds_policy.arn
  ]
}

# Lambda for the automated presigned database&s3 cleanup task
# TODO: Connect to event schedule
module "presigned_cleanup_lambda" {
  architecture          = var.architecture
  source                = "./modules/local_zip_lambda"
  function_name         = "docbox-presigned-cleanup-lambda"
  bootstrap_path        = "${path.module}/../target/lambda/docbox-presigned-cleanup-lambda/bootstrap"
  timeout               = 60
  memory_size           = 256
  environment_variables = local.shared_environment_variables
  additional_policy_arns = [
    # Provide access to S3 storage for docbox-* buckets
    aws_iam_policy.docbox_s3_access_policy.arn,
    # Provide database access
    aws_iam_policy.docbox_iam_rds_policy.arn,
    # TODO: Policy to allow execution via event
  ]
}

# Lambda for handling file processing on upload completion
module "upload_completion_lambda" {
  architecture   = var.architecture
  source         = "./modules/local_zip_lambda"
  function_name  = "docbox-upload-completion-lambda"
  bootstrap_path = "${path.module}/../target/lambda/docbox-upload-completion-lambda/bootstrap"
  timeout        = 900
  memory_size    = 2048
  environment_variables = merge(local.shared_environment_variables, {
    DOCBOX_OFFICE_CONVERTER             = "lambda"
    DOCBOX_CONVERT_LAMBDA_TMP_BUCKET    = module.office_converter_lambda.bucket
    DOCBOX_CONVERT_LAMBDA_FUNCTION_NAME = module.office_converter_lambda.function_name
  })

  additional_policy_arns = [
    # We need to attach the SQS Queue Execution role so that SQS can trigger this
    # lambda based on S3 events
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
    # Provide access the office converter temporary S3 bucket
    module.office_converter_lambda.s3_access_policy_arn,
    # Provide invoke access to the office converter lambda
    module.office_converter_lambda.invoke_policy_arn
  ]
}

# Lambda for authorizing request to the HTTP lambda
module "authorizer_lambda" {
  architecture          = var.architecture
  source                = "./modules/authorizer_js_lambda"
  function_name         = "docbox-authorizer-lambda"
  function_source       = file("authorizer.js")
  timeout               = 60
  memory_size           = 256
  environment_variables = local.shared_environment_variables
}
