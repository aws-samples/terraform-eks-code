rm -f ~/.kube/config
arn=$(aws sts get-caller-identity | jq -r .Arn)
aws eks update-kubeconfig --name $1
#aws eks update-kubeconfig --name $cn  --role-arn $arn
kubectx
echo "kubectl"
kubectl version --short
