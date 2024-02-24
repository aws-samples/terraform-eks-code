test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || "echo AWS_REGION is not set && exit"
test -n "$ACCOUNT_ID" && echo ACCOUNT_ID is "$ACCOUNT_ID" || "echo ACCOUNT_ID is not set && exit"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws/awsandy/docker-2048
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws/eks-distro/kubernetes/pause:3.5
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws/bitnami/aws-cli
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws/docker/library/busybox
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws/nginx/nginx
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws/karpenter/controller:v${1}
#
# karpenter stuff 
# no longer used by karpenter chart
#docker pull public.ecr.aws/karpenter/webhook:v${1}
#docker tag public.ecr.aws/karpenter/webhook:v${1} $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/karpenter/webhook:v${1}
#docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/karpenter/webhook:v${1}
