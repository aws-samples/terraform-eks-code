./setup-ng-ami.sh
time eksctl create nodegroup -f manng2.yml
kubectl get nodes
#eksctl utils update-cluster-logging --enable-types all --cluster ateks1 --approve
