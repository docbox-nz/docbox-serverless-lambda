variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type        = string
}

variable "aws_profile" {
  description = "The AWS cli profile to use"
  type        = string
}

variable "source_image_url" {
  description = "Source public ECR image"
  type        = string
  default     = "public.ecr.aws/jacobtread/office-convert-lambda"
}

variable "source_image_tag" {
  description = "Source public ECR image tag"
  type        = string
  default     = "0.1.0"
}


variable "architecture" {
  type        = string
  description = "The name of the Lambda function"
  default     = "arm64"
}
