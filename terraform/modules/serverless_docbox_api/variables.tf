variable "authorizer_lambda_invoke_arn" {
  type        = string
  description = "The invoke ARN the authorizer function"
}

variable "authorizer_lambda_function_name" {
  type        = string
  description = "The name of the authorizer lambda function"
}

variable "http_lambda_function_name" {
  type        = string
  description = "The function_name of the HTTP lambda to call through the API gateway"
}

variable "http_lambda_response_streaming_invoke_arn" {
  type        = string
  description = "The response_streaming_invoke_arn of the HTTP lambda to call through the API gateway"
}
