variable "function_name" {
  type        = string
  description = "The name of the Lambda function"
}

variable "zip_source" {
  type        = string
  description = "Either a local zip file path or the URL to download the zip file."

  validation {
    condition     = length(trimspace(var.zip_source)) > 0
    error_message = "The zip_source variable cannot be empty."
  }
}

variable "timeout" {
  type        = number
  default     = 60
  description = "The function execution timeout in seconds"
}

variable "memory_size" {
  type        = number
  default     = 512
  description = "The amount of memory in MB allocated to the function"
}

variable "additional_policy_arns" {
  type        = list(string)
  default     = []
  description = "Extra IAM policy ARNs to attach to this Lambda's role (e.g., SQS execution)"
}

variable "environment_variables" {
  type        = map(string)
  description = "The shared environment variables mapping required by Docbox services"
  default     = {}
}

variable "architecture" {
  type        = string
  description = "The architecture of the Lambda function"
  default     = "arm64"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime to use"
  default     = "provided.al2023"
}

variable "handler" {
  type        = string
  description = "Lambda handler"
  default     = "bootstrap"
}
