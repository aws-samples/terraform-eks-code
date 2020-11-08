aws cloudformation delete-stack --stack-name eksctl-mycluster1-nodegroup-custom-ng
aws cloudformation wait stack-delete-complete --stack-name eksctl-mycluster1-nodegroup-custom-ng
aws cloudformation delete-stack --stack-name eksctl-mycluster1-cluster
