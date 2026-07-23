# Name of the office converter function for invoking
output "function_name" {
  value = aws_lambda_function.office_converter.function_name
}

# ARN of the office converter function
output "function_arn" {
  value = aws_lambda_function.office_converter.arn
}

# ARN for the ECR containing the office converter image
output "ecr_arn" {
  value = aws_ecr_repository.docbox_ecr_private.arn
}

# ARN for the aws_iam_policy that allows access to the office converter temporary
# S3 bucket for uploading input files, downloading output files, and deleting both
output "s3_access_policy_arn" {
  value = aws_iam_policy.docbox_office_converter_s3_access_policy.arn
}

# ARN for the aws_iam_policy that allows invoking the office converter lambda
output "invoke_policy_arn" {
  value = aws_iam_policy.docbox_office_converter_invoke.arn
}

# S3 bucket for uploads and downloads
output "bucket" {
  value = aws_s3_bucket.docbox_office_converter_bucket.bucket
}
