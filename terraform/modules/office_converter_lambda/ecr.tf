locals {
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true

  # TODO: I NEED TO PULL THESE OVER
  script_hash = filemd5(local.is_windows ? "./scripts/pull-converter-image.ps1" : "./scripts/pull-converter-image.sh")
}

# ECR repository is required as the lambda cannot use an image from a public ECR
resource "aws_ecr_repository" "docbox_ecr_private" {
  name                 = "docbox-office-convert-lambda"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Use null_resource to trigger the pull-through cache
#
# This pulls the docker image for the lambda through the public ECR
# and into our private ECR
resource "null_resource" "trigger_cache_pull" {
  provisioner "local-exec" {
    command = templatefile(local.is_windows ? "./scripts/pull-converter-image.ps1" : "./scripts/pull-converter-image.sh", {
      aws_region  = var.aws_region
      aws_profile = var.aws_profile

      ecr_repo     = aws_ecr_repository.docbox_ecr_private.repository_url
      source_image = "${var.source_image_url}:${var.source_image_tag}"
      dest_image   = "${aws_ecr_repository.docbox_ecr_private.repository_url}:${var.source_image_tag}"
    })

    interpreter = local.is_windows ? ["PowerShell", "-Command"] : ["bash", "-c"]
    on_failure  = fail
  }

  # Re-run if the image tag or cache rule changes
  triggers = {
    image_ref   = "${var.source_image_url}:${var.source_image_tag}"
    ecr_repo    = aws_ecr_repository.docbox_ecr_private.id
    script_hash = local.script_hash
  }
}
