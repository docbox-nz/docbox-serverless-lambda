output "rest_api_id" {
  description = "ID of the docbox REST API"
  value       = module.serverless_docbox.rest_api_id
}

output "api_endpoint" {
  description = "The public URL for the docbox API"
  value       = module.serverless_docbox.api_endpoint
}
