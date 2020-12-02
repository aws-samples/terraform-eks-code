

Debug:

kubectl describe pods  coredns-6987776bbd-c9q4z -n kube-system

kubectl rollout restart deployment deployment-2048 -n game-2048
kubectl rollout restart deployment coredns -n kube-system


kubectl get nodes 
kubectl get nodes --show-labels
kubectl get node --selector='eks.amazonaws.com/nodegroup==ng2-mycluster1


