kubectl describe deployment -n kube-system aws-load-balancer-controller
helm list -A
helm delete aws-load-balancer-controller -n kube-system
kubectl delete -f crds.yaml 
