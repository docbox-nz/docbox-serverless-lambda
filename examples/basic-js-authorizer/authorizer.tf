
# ZIP for the authorizer js file
data "archive_file" "authorizer_zip" {
  type        = "zip"
  output_path = "${path.module}/authorizer.zip"

  source {
    filename = "index.js"
    content  = file("${path.module}/authorizer.js")
  }
}

# Lambda
module "authorizer_lambda" {
  source  = "jacobtread/simple-zip-lambda/aws"
  version = "0.1.0"

  architecture  = var.architecture
  zip_source    = data.archive_file.authorizer_zip.output_path
  function_name = "docbox-authorizer-lambda"
  timeout       = 60
  memory_size   = 256
  handler       = "index.handler"
  runtime       = "nodejs22.x"
}
