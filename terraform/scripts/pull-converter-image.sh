aws ecr get-login-password --region ${aws_region} --profile ${aws_profile} | \
docker login --username AWS --password-stdin ${ecr_repo} && \
docker pull  --platform linux/arm64 ${source_image} && \
docker tag ${source_image} ${dest_image} && \
docker push --platform linux/arm64 ${dest_image} && \
docker logout ${ecr_repo} && \
sleep 5
