# TODO: Connect to event schedule
locals {
  upload_completion_lambda_environment_variables = merge(local.shared_environment_variables, {
    DOCBOX_OFFICE_CONVERTER             = "lambda"
    DOCBOX_CONVERT_LAMBDA_TMP_BUCKET    = module.office_converter_lambda.bucket
    DOCBOX_CONVERT_LAMBDA_FUNCTION_NAME = module.office_converter_lambda.function_name
  })
  upload_completion_lambda_policies = concat(var.policy_arns, [
    # We need to attach the SQS Queue Execution role so that SQS can trigger this
    # lambda based on S3 events
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
    # Provide access the office converter temporary S3 bucket
    module.office_converter_lambda.s3_access_policy_arn,
    # Provide invoke access to the office converter lambda
    module.office_converter_lambda.invoke_policy_arn
  ])


  upload_completion_lambda_timeout       = 900
  upload_completion_lambda_memory_size   = 2048
  upload_completion_lambda_function_name = "docbox-upload-completion-lambda"

  upload_completion_lambda_zip_path     = "${path.module}/../target/lambda/docbox-upload-completion-lambda/bootstrap.zip"
  upload_completion_lambda_download_url = "${local.serverless_base_url}/docbox-upload-completion-lambda-${local.serverless_zip_arch}.zip"
}

# Lambda for performing office file conversion
module "office_converter_lambda" {
  aws_profile  = var.aws_profile
  aws_region   = var.aws_region
  architecture = var.architecture
  source       = "../office_converter_lambda"
}

# Lambda for handling file processing on upload completion
module "upload_completion_lambda" {
  architecture           = var.architecture
  source                 = "../zip_lambda"
  function_name          = local.upload_completion_lambda_function_name
  zip_source             = var.use_local_zip ? local.upload_completion_lambda_zip_path : local.upload_completion_lambda_download_url
  timeout                = local.upload_completion_lambda_timeout
  memory_size            = local.upload_completion_lambda_memory_size
  environment_variables  = local.upload_completion_lambda_environment_variables
  additional_policy_arns = local.upload_completion_lambda_policies
}

# Queue for file upload messages
resource "aws_sqs_queue" "docbox_queue" {
  name = "docbox-s3-upload-queue"
  tags = {
    Name = "docbox-sqs-queue"
  }
}

# Pass events from the S3 upload queue to the upload completion lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.docbox_queue.arn
  function_name    = module.upload_completion_lambda.function_name
  batch_size       = 1 # Perform trigger in 1 item batches to make failure easier to handle
  depends_on       = [module.upload_completion_lambda]
}


# Policy on the docbox S3 notification SQS queue that permits AWS S3
# to push new messages onto the queue
resource "aws_sqs_queue_policy" "docbox_s3_sqs_policy" {
  queue_url = aws_sqs_queue.docbox_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "docbox-queue-events"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.docbox_queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::docbox-*"
          }
        }
      }
    ]
  })
}
