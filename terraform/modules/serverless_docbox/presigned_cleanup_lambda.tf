# TODO: Connect to event schedule
locals {
  presigned_cleanup_lambda_environment_variables = local.shared_environment_variables
  presigned_cleanup_lambda_policies = concat(var.policy_arns, [
    # Provide access to S3 storage for docbox-* buckets
    aws_iam_policy.docbox_s3_access_policy.arn,
    # TODO: Policy to allow execution via event
  ])


  presigned_cleanup_lambda_timeout       = 60
  presigned_cleanup_lambda_memory_size   = 256
  presigned_cleanup_lambda_function_name = "docbox-presigned-cleanup-lambda"

  presigned_cleanup_lambda_zip_path     = "${path.module}/../target/lambda/docbox-presigned-cleanup-lambda/bootstrap.zip"
  presigned_cleanup_lambda_download_url = "${local.serverless_base_url}/docbox-presigned-cleanup-lambda-${local.serverless_zip_arch}.zip"

}

# Lambda for the automated presigned database&s3 cleanup task
module "presigned_cleanup_lambda" {
  architecture           = var.architecture
  source                 = "../zip_lambda"
  function_name          = local.presigned_cleanup_lambda_function_name
  zip_source             = var.use_local_zip ? local.presigned_cleanup_lambda_zip_path : local.presigned_cleanup_lambda_download_url
  timeout                = local.presigned_cleanup_lambda_timeout
  memory_size            = local.presigned_cleanup_lambda_memory_size
  environment_variables  = local.presigned_cleanup_lambda_environment_variables
  additional_policy_arns = local.presigned_cleanup_lambda_policies
}
