nc=`aws eks list-clusters | jq '.clusters | length'`
if [ $nc == 1 ] ; then
export CLUSTER=`aws eks list-clusters | jq '.clusters[0]' | tr -d '"'`
echo "EKS Cluster = $CLUSTER"
else
echo "Please set the environment variable CLUSTER"
exit
fi
kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
kubectl describe daemonset aws-node -n kube-system | grep -A5 Environment
INSTANCE_IDS=(`aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters "Name=tag-key,Values=eks:cluster-name" "Name=instance-state-name,Values=running" "Name=tag-value,Values=$CLUSTER" --output text` )
target=$(kubectl get nodes | grep Read | wc -l)
curr=0
for i in "${INSTANCE_IDS[@]}"
do
echo "Terminating EC2 instance $i ... "
aws ec2 terminate-instances --instance-ids $i
while [ $curr -ne $target ]; do
    stat=$(aws ec2 describe-instance-status --instance-ids $i  --include-all-instances | jq -r .InstanceStatuses[0].InstanceState.Name)
    echo $stat
    if [ "$stat" == "terminated" ]; then
        sleep 5
        curr=$(kubectl get nodes | grep -v NotReady | grep Read | wc -l)
        kubectl get nodes
        echo "Current Ready nodes = $curr of $target"
    fi
done
done