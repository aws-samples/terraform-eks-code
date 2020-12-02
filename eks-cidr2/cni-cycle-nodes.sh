test -n "$1" && echo CLUSTER is "$7" || "echo CLUSTER is not set && exit"
CLUSTER=$(echo $1)
kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
kubectl describe daemonset aws-node -n kube-system | grep -A5 Environment | grep CUSTOM
INSTANCE_IDS=(`aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters "Name=tag-key,Values=eks:cluster-name" "Name=instance-state-name,Values=running" "Name=tag-value,Values=$CLUSTER" --output text` )
target=$(kubectl get nodes | grep Read | wc -l)
for i in "${INSTANCE_IDS[@]}"
do
curr=0
echo "Terminating EC2 instance $i ... "
aws ec2 terminate-instances --instance-ids $i | jq -r .TerminatingInstances[0].CurrentState.Name
while [ $curr -ne $target ]; do
    stat=$(aws ec2 describe-instance-status --instance-ids $i  --include-all-instances | jq -r .InstanceStatuses[0].InstanceState.Name)
    
    if [ "$stat" == "terminated" ]; then
        sleep 15
        curr=$(kubectl get nodes | grep -v NotReady | grep Read | wc -l)
        kubectl get nodes
        echo "Current Ready nodes = $curr of $target"
    fi
    if [ "$stat" != "terminated" ]; then
        sleep 10
        echo "$i $stat"
    fi
done
done
echo "done"