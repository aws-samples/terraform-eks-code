


test -n "$1" && echo REGION is "$1" || "echo REGION is not set && exit"
test -n "$2" && echo CLUSTER is "$2" || "echo CLUSTER is not set && exit"
test -n "$3" && echo ACCOUNT is "$3" || "echo ACCOUNT is not set && exit"
test -n "$LBC_VERSION" && echo LBC_VERSION is "$LBC_VERSION" || "LBC_VERSION=2.1.0"


kubectl delete -f v2_1_0_full.yaml

kubectl delete --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.2/cert-manager.yaml

eksctl delete iamserviceaccount --cluster mycluster1 --namespace=kube-system --name=aws-load-balancer-controller 
aws iam delete-policy --policy-arnarn:aws:iam::566972129212:policy/AWSLoadBalancerControllerIAMPolicy


