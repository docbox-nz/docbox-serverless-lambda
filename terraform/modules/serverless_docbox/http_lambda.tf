locals {
  http_lambda_environment_variables = merge(local.shared_environment_variables, {
    AWS_LAMBDA_HTTP_IGNORE_STAGE_IN_PATH = "true",
  })

  http_lambda_policies = concat(var.policy_arns, [
    # Provide access to S3 storage for docbox-* buckets
    aws_iam_policy.docbox_s3_access_policy.arn,
  ])

  http_lambda_zip_path     = "${path.module}/../../../target/lambda/docbox-http-lambda/bootstrap.zip"
  http_lambda_download_url = "${local.serverless_base_url}/docbox-http-lambda-${local.serverless_zip_arch}.zip"
}

# Lambda for docbox HTTP API
module "http_lambda" {
  architecture           = var.architecture
  source                 = "../zip_lambda"
  zip_source             = var.use_local_zip ? local.http_lambda_zip_path : local.http_lambda_download_url
  function_name          = var.http_lambda_function_name
  timeout                = var.http_lambda_timeout
  memory_size            = var.http_lambda_memory_size
  environment_variables  = local.http_lambda_environment_variables
  additional_policy_arns = local.http_lambda_policies
}
