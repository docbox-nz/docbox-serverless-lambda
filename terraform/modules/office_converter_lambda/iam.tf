# Role for the office converter lambda
resource "aws_iam_role" "docbox_office_converter_role" {
  name = "docbox_office_converter_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach the AWSLambdaBasicExecutionRole role policy
resource "aws_iam_role_policy_attachment" "docbox_office_converter_role_basic_execution" {
  role       = aws_iam_role.docbox_office_converter_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# IAM Policy that allows performing the following actions on S3 scoped to
# the office converter temporary bucket:
# - Upload files
# - Get files
# - Delete files
# This is granted to both the office converter role and the docbox role
# (Docbox must store input and read output, converter must read, store, and delete)
resource "aws_iam_policy" "docbox_office_converter_s3_access_policy" {
  name        = "docbox_office_converter_s3_access_policy"
  description = "Allows S3 access to the office converter temporary bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.docbox_office_converter_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach the "docbox_sqs_read" policy to the office converter role
resource "aws_iam_role_policy_attachment" "docbox_office_converter_role_converter_s3_access" {
  role       = aws_iam_role.docbox_office_converter_role.name
  policy_arn = aws_iam_policy.docbox_office_converter_s3_access_policy.arn
}

# IAM Policy to allow invoking the converter lambda
resource "aws_iam_policy" "docbox_office_converter_invoke" {
  name        = "docbox-office-converter-invoke-policy"
  description = "Allows invoking the office converter lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = aws_lambda_function.office_converter.arn
      }
    ]
  })
}
