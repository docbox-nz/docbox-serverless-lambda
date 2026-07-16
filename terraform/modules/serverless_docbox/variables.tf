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
