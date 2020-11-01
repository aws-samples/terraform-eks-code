rm -f ~/.kube/config
cn=`terraform output cluster-name`
arn=$(aws sts get-caller-identity | jq -r .Arn)
aws eks update-kubeconfig --name $cn
#aws eks update-kubeconfig --name $cn  --role-arn $arn
kubectx
