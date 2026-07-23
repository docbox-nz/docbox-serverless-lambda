locals {
  management_lambda_environment_variables = merge(local.shared_environment_variables, {
    DOCBOX_MANAGEMENT_CONFIG_SECRET_NAME = var.management_config_secret_id
  })
  management_lambda_policies = concat(var.policy_arns, var.management_policy_arns, [
    aws_iam_policy.docbox_management_lambda_s3.arn
  ])


  management_lambda_timeout       = 60
  management_lambda_memory_size   = 256
  management_lambda_function_name = "docbox-management-lambda"

  management_lambda_zip_path     = "${path.module}/../../../target/lambda/docbox-management-lambda/bootstrap.zip"
  management_lambda_download_url = "${local.serverless_base_url}/docbox-management-lambda-${local.serverless_zip_arch}.zip"

}

# Lambda for management of the serverless docbox setup
# (Since in most cases its not going to be easy to access the database and other resources directly)
module "management_lambda" {
  architecture           = var.architecture
  source                 = "../zip_lambda"
  function_name          = local.management_lambda_function_name
  zip_source             = var.use_local_zip ? local.management_lambda_zip_path : local.management_lambda_download_url
  timeout                = local.management_lambda_timeout
  memory_size            = local.management_lambda_memory_size
  environment_variables  = local.management_lambda_environment_variables
  additional_policy_arns = local.management_lambda_policies
}

# http://a0e649480156353ea2724e13d689cd53.lambda-url.us-east-1.localhost:4566/
resource "aws_iam_policy" "docbox_management_lambda_s3" {
  name        = "docbox-management-lambda-s3-access"
  description = "Allows management of docbox S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Bucket level actions
      {
        Effect = "Allow"
        Action = [
          "s3:HeadBucket",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketNotificationConfiguration",
          "s3:PutBucketCors",
          "s3:GetBucketLifecycleConfiguration",
          "s3:PutBucketLifecycleConfiguration",
        ]
        Resource = [
          "arn:aws:s3:::docbox-*",
        ]
      }
    ]
  })
}
