./setup-ng.sh
time eksctl create nodegroup -f manng-nodegroup.yml
kubectl get nodes
#eksctl utils update-cluster-logging --enable-types all --cluster ateks1 --approve

