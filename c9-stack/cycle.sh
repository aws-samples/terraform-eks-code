aws cloudformation delete-stack --stack-name mytest
sleep 4
aws cloudformation create-stack --template-body file://c9.json --stack-name mytest