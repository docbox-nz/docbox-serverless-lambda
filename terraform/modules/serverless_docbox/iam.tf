# IAM Policy that allows the docbox role to perform the following actions on S3 scoped to docbox-* buckets:
# - Upload files
# - Tag uploaded files
# - Get files
# - Delete files
resource "aws_iam_policy" "docbox_s3_access_policy" {
  name        = "docbox_s3_access_policy"
  description = "Allows S3 access to freely modify any buckets prefixed with docbox- for the docbox EC2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Object level actions
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::docbox-*/*"
        ]
      }
    ]
  })
}
