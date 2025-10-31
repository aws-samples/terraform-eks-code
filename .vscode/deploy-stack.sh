# delete role eksworkshop-admin
# create WSParticipantRole. 
aws cloudformation create-stack --stack-name vscode \
--template-body file://vscode-isengard.yaml --capabilities CAPABILITY_NAMED_IAM \
--parameters ParameterKey=DefaultVpcId,ParameterValue=vpc-db7c09b3 \
--region eu-west-2
