
# Temporary bucket for the office converter lambda to use
resource "aws_s3_bucket" "docbox_office_converter_bucket" {
  bucket = "docbox-office-converter-tmp"
}

# Enforce a short 1 day lifecycle for objects within the temporary bucket
resource "aws_s3_bucket_lifecycle_configuration" "docbox_office_converter_bucket_lifecycle" {
  bucket = aws_s3_bucket.docbox_office_converter_bucket.id

  rule {
    id     = "expire-after-1-day"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }
  }
}
