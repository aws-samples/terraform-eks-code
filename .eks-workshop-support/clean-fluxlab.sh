aws codecommit delete-repository --repository-name eks-workshop-gitops 
rm -f /home/ec2-user/.ssh/gitops_ssh.pem
aws codecommit delete-repository --repository-name eks-workshop-retail-store-sample
parn=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName=="eks-workshop-ecr-ui").Arn')
aws iam detach-role-policy --policy-arn $parn --role-name eks-workshop-ecr-ui
aws iam delete-policy --policy-arn $parn
aws iam delete-role --role-name eks-workshop-ecr-ui
aws iam delete-role-policy --role-name eks-workshop-codepipeline-role --policy-name eks-workshop-codepipeline-policy
aws iam delete-role --role-name eks-workshop-codepipeline-role
aws iam delete-role-policy --role-name eks-workshop-codebuild-role --policy-name codebuild_policy
aws iam delete-role --role-name eks-workshop-codebuild-role 
parn=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName=="eks-workshop-ci-access").Arn')
aws iam detach-user-policy --user-name eks-workshop-gitops --policy-arn $parn
aws iam delete-policy --policy-arn $parn
parn=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName=="eks-workshop-gitops").Arn')
aws iam detach-user-policy --user-name eks-workshop-gitops --policy-arn $parn
aws iam delete-policy --policy-arn $parn
pubk=$(aws iam list-ssh-public-keys --user-name eks-workshop-gitops --query 'SSHPublicKeys[].SSHPublicKeyId' --output text)
aws iam delete-ssh-public-key --user-name eks-workshop-gitops --ssh-public-key-id $pubk
aws iam delete-user --user-name eks-workshop-gitops
aws codebuild delete-project --name eks-workshop-retail-store-sample-manifest
aws codebuild delete-project --name eks-workshop-retail-store-sample-amd64
aws codebuild delete-project --name eks-workshop-retail-store-sample-arm64
aws codepipeline delete-pipeline --name eks-workshop-retail-store-sample
#helm uninstall aws-load-balancer-controller -n kube-system