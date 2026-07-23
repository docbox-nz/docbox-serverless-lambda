variable "architecture" {
  type        = string
  description = "The architecture of the Lambda function"
  default     = "arm64"
}

variable "use_local_zip" {
  type        = bool
  description = "Whether to use a local zip of docbox"
  default     = false
}

variable "policy_arns" {
  type        = list(string)
  description = "ARNs of required IAM policies for the lambdas (HTTP, Presigned Cleanup, Upload Completion) include your database IAM policy ARN here "
}

variable "management_policy_arns" {
  type        = list(string)
  description = "ARNs of required IAM policies for the the management lambda, these should be the policies that allow it to perform required setup actions"
}


variable "management_config_secret_id" {
  type        = string
  description = "ID of the secret that the management config is stored in"
}

variable "environment_variables" {
  type        = map(string)
  description = "The shared environment variables mapping required by Docbox services"
  default     = {}
}

variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type        = string
}

variable "aws_profile" {
  description = "The AWS cli profile to use"
  type        = string
}

variable "http_lambda_timeout" {
  description = "Timeout for the http lambda"
  default     = 60
}

variable "http_lambda_memory_size" {
  description = "Memory size for the http lambda"
  type        = number
  default     = 256
}

variable "http_lambda_function_name" {
  description = "Function name for the http lambda"
  type        = string
  default     = "docbox-http-lambda"
}

variable "upload_completion_lambda_timeout" {
  description = "Timeout for the file upload completion lambda"
  type        = number
  default     = 900
}

variable "upload_completion_lambda_memory_size" {
  description = "Memory size for the file upload completion lambda"
  type        = number
  default     = 512
}

variable "upload_completion_lambda_function_name" {
  description = "Function name for the upload completion lambda"
  type        = string
  default     = "docbox-upload-completion-lambda"
}

variable "management_lambda_timeout" {
  description = "Timeout for the management lambda"
  default     = 60
}

variable "management_lambda_memory_size" {
  description = "Memory size for the management lambda"
  type        = number
  default     = 128
}

variable "management_lambda_function_name" {
  description = "Function name for the management lambda"
  type        = string
  default     = "docbox-management-lambda"
}

variable "cleanup_lambda_timeout" {
  description = "Timeout for the cleanup lambda"
  default     = 180
}

variable "cleanup_lambda_memory_size" {
  description = "Memory size for the cleanup lambda"
  type        = number
  default     = 256
}

variable "cleanup_lambda_function_name" {
  description = "Function name for the cleanup lambda"
  type        = string
  default     = "docbox-cleanup-lambda"
}

variable "cleanup_schedule_expression" {
  description = "Schedule expression for how often the cleanup lambda should run"
  type        = string
  default     = "rate(1 day)"
}
