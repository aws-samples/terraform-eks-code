# delete role eksworkshop-admin
# create WSParticipantRole. 
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --region eu-west-2 --output text)
aws cloudformation create-stack --stack-name vscode \
--template-body file://vscode-isengard.yaml --capabilities CAPABILITY_NAMED_IAM \
--parameters ParameterKey=DefaultVpcId,ParameterValue=$DEFAULT_VPC_ID \
--region eu-west-2
