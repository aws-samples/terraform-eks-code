# delete role eksworkshop-admin
# create WSParticipantRole. 
aws cloudformation create-stack --stack-name vscode --template-body file://vscode-server.yaml --capabilities CAPABILITY_NAMED_IAM
