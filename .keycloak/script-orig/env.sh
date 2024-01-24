export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=$(aws configure get region)
export CLUSTER_NAME=mgmt-workshop
#export HOSTED_ZONE=<your-public-domain>  # dns name awsandy.people.aws.dev
export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
export CLUSTER_VERSION=1.27
echo $ACCOUNT_ID
echo $AWS_REGION
echo $CLUSTER_NAME
echo $HOSTED_ZONE
echo $CLUSTER_VERSION