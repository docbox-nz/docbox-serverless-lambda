# Lambda for performing office file conversions (https://github.com/jacobtread/office-convert-lambda)
resource "aws_lambda_function" "office_converter" {
  function_name = "docbox-office-convert-lambda"
  role          = aws_iam_role.docbox_office_converter_role.arn
  package_type  = "Image"

  architectures = [var.architecture]

  image_uri = "${aws_ecr_repository.docbox_ecr_private.repository_url}:${var.source_image_tag}"

  timeout     = 60
  memory_size = 2048

  environment {
    variables = {
      // Tell the converter to abort and kill the program if it
      // spends longer than 55s trying to convert a file
      // (Consider the program to have hanged)
      "CONVERT_TIMEOUT_SECONDS" = "55"
    }
  }

  depends_on = [
    null_resource.trigger_cache_pull
  ]
}
