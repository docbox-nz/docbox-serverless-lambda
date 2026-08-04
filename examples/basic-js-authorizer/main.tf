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


# Base docbox infra
module "serverless_docbox" {
  source  = "docbox-nz/docbox-serverless-lambda/aws"
  version = "0.0.7"

  aws_profile  = var.aws_profile
  aws_region   = var.aws_region
  architecture = var.architecture

  # Base environment variables for all the lambdas
  environment_variables = {
    RUST_LOG                    = "debug,docbox_core::notifications::sqs=info"
    DOCBOX_DB_HOST              = aws_db_instance.postgres.address
    DOCBOX_DB_PORT              = tostring(aws_db_instance.postgres.port)
    DOCBOX_DB_ROOT_IAM          = "true"
    DOCBOX_SEARCH_INDEX_FACTORY = "database",
    LOCAL_DEVELOPMENT           = tostring(var.local_deploy_override),
  }

  # Base policies for all the lambdas
  policy_arns = [
    # Provide database access
    aws_iam_policy.docbox_iam_rds_policy.arn
  ]

  # Provide the management lambda secret
  management_config_secret_id = aws_secretsmanager_secret.config_secret.id

  # Provide the authorizer
  authorizer_lambda_function_name = module.authorizer_lambda.function_name
  authorizer_lambda_invoke_arn    = module.authorizer_lambda.function_invoke_arn
}

# Setup a configuration secret for the management lambda
resource "aws_secretsmanager_secret" "config_secret" {
  name        = "docbox-management-config-secret"
  description = "Secret containing the management configuration for docbox"
}

resource "aws_secretsmanager_secret_version" "config_secret_version" {
  secret_id = aws_secretsmanager_secret.config_secret.id
  secret_string = jsonencode({
    api = {
      url = module.serverless_docbox.api_endpoint
    }
    database = {
      host                   = aws_db_instance.postgres.address
      port                   = aws_db_instance.postgres.port
      setup_user_secret_name = aws_db_instance.postgres.master_user_secret[0].secret_arn
      root_iam               = true
    }
    search = {
      provider = "database"
    }
    secrets = {
      provider = "aws"
    }
    storage = {
      provider = "s3"
    }
  })
}
