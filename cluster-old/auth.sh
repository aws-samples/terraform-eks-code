rm -f ~/.kube/config
arn=$(aws sts get-caller-identity | jq -r .Arn)
aws eks update-kubeconfig --name $1
kubectx
echo "kubectl"
kubectl version
# pre-set some CNI options before nodes are created
kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
#kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_EXTERNALSNAT=true
echo "CNI options"
kubectl describe daemonset aws-node -n kube-system | grep CNI_CUSTOM | tr -d ' '
kubectl describe daemonset aws-node -n kube-system | grep AWS_VPC_K8S_CNI_EXTERNALSNAT | tr -d ' '