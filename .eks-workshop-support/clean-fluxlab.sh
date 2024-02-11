aws codecommit delete-repository --repository-name mycluster1-gitops 
rm -f /home/ec2-user/.ssh/gitops_ssh.pem
aws codecommit delete-repository --repository-name mycluster1-retail-store-sample
parn=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName=="mycluster1-ecr-ui").Arn')
aws iam detach-role-policy --policy-arn $parn --role-name mycluster1-ecr-ui
aws iam delete-policy --policy-arn $parn
aws iam delete-role --role-name mycluster1-ecr-ui
aws iam delete-role-policy --role-name mycluster1-codepipeline-role --policy-name mycluster1-codepipeline-policy
aws iam delete-role --role-name mycluster1-codepipeline-role
aws iam delete-role-policy --role-name mycluster1-codebuild-role --policy-name codebuild_policy
aws iam delete-role --role-name mycluster1-codebuild-role 
parn=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName=="mycluster1-ci-access").Arn')
aws iam detach-user-policy --user-name mycluster1-gitops --policy-arn $parn
aws iam delete-policy --policy-arn $parn
parn=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName=="mycluster1-gitops").Arn')
aws iam detach-user-policy --user-name mycluster1-gitops --policy-arn $parn
aws iam delete-policy --policy-arn $parn
pubk=$(aws iam list-ssh-public-keys --user-name mycluster1-gitops --query 'SSHPublicKeys[].SSHPublicKeyId' --output text)
aws iam delete-ssh-public-key --user-name mycluster1-gitops --ssh-public-key-id $pubk
aws iam delete-user --user-name mycluster1-gitops
aws codebuild delete-project --name mycluster1-retail-store-sample-manifest
aws codebuild delete-project --name mycluster1-retail-store-sample-amd64
aws codebuild delete-project --name mycluster1-retail-store-sample-arm64
aws codepipeline delete-pipeline --name mycluster1-retail-store-sample
helm uninstall aws-load-balancer-controller -n kube-system