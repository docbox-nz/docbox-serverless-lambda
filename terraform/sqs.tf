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
