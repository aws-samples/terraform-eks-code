# delete role eksworkshop-admin
# create WSParticipantRole.
echo "Building in eu-west-1"
aws iam detach-role-policy --role-name eksworkshop-admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ir=$(aws iam list-instance-profiles | grep vscode | grep InstanceProfileName | cut -f2 -d':' | cut -f2 -d'"')
aws iam remove-role-from-instance-profile --instance-profile-name $ir --role-name eksworkshop-admin
aws iam delete-role --role-name eksworkshop-admin
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --region eu-west-1 --output text)
aws cloudformation create-stack --stack-name vscode \
--template-body file://vscode-isengard.yaml --capabilities CAPABILITY_NAMED_IAM \
--parameters ParameterKey=DefaultVpcId,ParameterValue=$DEFAULT_VPC_ID \
--region eu-west-1
echo "connect with connect.sh"
