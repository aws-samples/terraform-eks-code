test -n "$1" && echo CLUSTER is "$1" || "echo CLUSTER is not set && exit"
CLUSTER=$(echo $1)
# set custom networking for the CNI
kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
# quick look to see if it's now set
kubectl describe daemonset aws-node -n kube-system | grep -A5 Environment | grep CUSTOM
# Get a list of all the instances in the node group
comm=`printf "aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters \"Name=tag-key,Values=eks:nodegroup-name\" \"Name=tag-value,Values=ng1-%s\" \"Name=instance-state-name,Values=running\" --output text" $CLUSTER`
INSTANCE_IDS=(`eval $comm`)
target=$(kubectl get nodes | grep Read | wc -l)
# iterate through nodes - terminate one at a time
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