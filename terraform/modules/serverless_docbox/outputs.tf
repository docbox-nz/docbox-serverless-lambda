# ARN for the S3 upload topic
output "sqs_upload_notifications_arn" {
  value = aws_sqs_queue.docbox_queue.arn
}

# URL for the uploads event queue
output "sqs_upload_queue_url" {
  value = aws_sqs_queue.docbox_queue.url
}

# Streaming invoke ARN for the HTTP lambda
output "http_lambda_response_streaming_invoke_arn" {
  value = module.http_lambda.response_streaming_invoke_arn
}

# Function name of the HTTP lambda
output "http_lambda_function_name" {
  value = module.http_lambda.function_name
}
