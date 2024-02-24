test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || "echo AWS_REGION is not set && exit"
test -n "$ACCOUNT_ID" && echo ACCOUNT_ID is "$ACCOUNT_ID" || "echo ACCOUNT_ID is not set && exit"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
#docker pull alexwhen/docker-2048
#docker tag docker-2048 aws_account_id.dkr.ecr.region.amazonaws.com/docker-2048
dirs="nginx busybox"
for i in $dirs; do
docker pull $i
docker tag $i $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$i
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$i
done

docker pull amazon/aws-cli 
docker tag amazon/aws-cli $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws-cli
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws-cli

docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws/awsandy/sample-app
docker tag public.ecr.aws/awsandy/docker-2048 $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/sample-app
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/sample-app
docker pull public.ecr.aws/eks-distro/kubernetes/pause:3.5
docker tag public.ecr.aws/eks-distro/kubernetes/pause:3.5 $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/pause:3.5
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/pause:3.5
#
# karpenter stuff 
# no longer used by karpenter chart
#docker pull public.ecr.aws/karpenter/webhook:v${1}
#docker tag public.ecr.aws/karpenter/webhook:v${1} $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/karpenter/webhook:v${1}
#docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/karpenter/webhook:v${1}
docker pull public.ecr.aws/karpenter/controller:v${1}
docker tag public.ecr.aws/karpenter/controller:v${1} $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/karpenter/controller:v${1}
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/karpenter/controller:v${1}