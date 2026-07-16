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

# Invoke ARN of the lambda function
output "invoke_policy_arn" {
  value = aws_iam_role.lambda_exec.arn
}
