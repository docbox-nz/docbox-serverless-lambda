# Output the API endpoint
output "rest_api_id" {
  description = "ID of the docbox REST API"
  value       = aws_api_gateway_stage.default.rest_api_id
}

# Output the API endpoint
output "api_endpoint" {
  description = "The public URL for the docbox API"
  value       = aws_api_gateway_stage.default.invoke_url
}
