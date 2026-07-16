# Name of the lambda function
output "function_name" {
  value = aws_lambda_function.this.function_name
}

# ARN of the lambda function
output "function_arn" {
  value = aws_lambda_function.this.arn
}

# Invoke ARN of the lambda function
output "function_invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}

# Response streaming invoke ARN
output "response_streaming_invoke_arn" {
  value = aws_lambda_function.this.response_streaming_invoke_arn
}

# Invoke ARN of the lambda function
output "invoke_policy_arn" {
  value = aws_iam_role.lambda_exec.arn
}
