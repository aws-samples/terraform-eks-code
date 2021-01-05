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

#docker pull alexwhen/docker-2048 
#docker tag alexwhen/docker-2048 $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/sample-app
#docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/sample-app

docker pull public.ecr.aws/awsandy/docker-2048 
docker tag public.ecr.aws/awsandy/docker-2048 $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/sample-app
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/sample-app