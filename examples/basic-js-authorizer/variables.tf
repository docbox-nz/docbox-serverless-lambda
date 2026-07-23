
variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "The AWS cli profile to use"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to allocate resources within"
  type        = string
}

variable "architecture" {
  type        = string
  description = "The name of the Lambda function"
  default     = "arm64"
}

variable "use_local_zip" {
  type        = bool
  description = "Whether to use a local zip of docbox"
  default     = false
}

variable "local_deploy_override" {
  type        = bool
  description = "Whether to override behavior so that it works with local deployments (floci / localstack)"
  default     = false
}
