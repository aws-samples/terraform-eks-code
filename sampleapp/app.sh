#kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/examples/2048/2048_full.yaml
wget https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/examples/2048/2048_full.yaml
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com
docker pull alexwhen/docker-2048

docker tag docker-2048 aws_account_id.dkr.ecr.region.amazonaws.com/docker-2048

docker pull busybox
docker tag busybox 566972129213.dkr.ecr.eu-west-1.amazonaws.com/busybox
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 566972129213.dkr.ecr.eu-west-1.amazonaws.com
aws ecr create-repository --repository-name busybox --region eu-west-1
docker push 566972129213.dkr.ecr.eu-west-1.amazonaws.com/busybox