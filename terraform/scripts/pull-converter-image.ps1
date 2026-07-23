$pass = aws ecr get-login-password --region ${aws_region} --profile ${aws_profile}

# Password is passed through --password instead of --password-stdin because powershell is
# refusing to handle piping this properly
docker login --username AWS --password $pass ${ecr_repo}

docker pull --platform linux/arm64 ${source_image}
docker tag ${source_image} ${dest_image}
docker push --platform linux/arm64 ${dest_image}
docker logout ${ecr_repo}

# Sleep briefly to ensure ECR registers the image before we can use it
Start-Sleep -Seconds 5
