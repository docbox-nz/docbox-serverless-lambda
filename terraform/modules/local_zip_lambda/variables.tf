variable "function_name" {
  type        = string
  description = "The name of the Lambda function"
}

variable "bootstrap_path" {
  type        = string
  description = "Path to the bootstrap file"
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
}

variable "architecture" {
  type        = string
  description = "The name of the Lambda function"
  default     = "arm64"
}
