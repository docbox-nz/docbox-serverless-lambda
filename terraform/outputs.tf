# ARN for the S3 upload topic
output "sqs_upload_notifications_arn" {
  value = aws_sqs_queue.docbox_queue.arn
}

# URL for the uploads event queue
output "sqs_upload_queue_url" {
  value = aws_sqs_queue.docbox_queue.url
}

# Output the API endpoint
output "api_endpoint" {
  description = "The public URL for the docbox API"
  value       = aws_api_gateway_stage.default.invoke_url
}

# Output the API endpoint
output "database" {
  description = "The public URL for the docbox API"
  value       = aws_db_instance.postgres.address
}
