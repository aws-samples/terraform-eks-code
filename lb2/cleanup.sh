kubectl describe deployment -n kube-system aws-load-balancer-controller
helm list -A
echo "Remove helm deployment"
helm delete aws-load-balancer-controller -n kube-system
echo "Remove CRD"
kubectl delete -f crds.yaml
#aws iam delete-policy --policy-arnarn:aws:iam::$AWS_ACCOUNT:policy/AWSLoadBalancerControllerIAMPolicy
