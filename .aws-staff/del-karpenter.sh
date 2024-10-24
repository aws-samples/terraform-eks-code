# kubectl logs -l app.kubernetes.io/instance=karpenter -n kube-system | jq '.'
kubectl delete nodepool default
kubectl delete ec2nodeclass default
kubectl -n kube-system scale deployment karpenter --replicas 0
sleep 5 
kubectl -n kube-system scale deployment karpenter --replicas 2
#terraform apply -replace="kubectl_manifest.karpenter_node_class"