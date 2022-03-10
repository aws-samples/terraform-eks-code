comm=`printf "aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters \"Name=tag-key,Values=karpenter.sh/provisioner-name\" \"Name=tag-value,Values=default\" \"Name=instance-state-name,Values=running\" --output text" $CLUSTER`
INSTANCE_IDS=(`eval $comm`)
for i in "${INSTANCE_IDS[0]}"
do
echo "Descr EC2 instance $i ..."
sg0=`aws ec2 describe-instances --instance-ids $i | jq -r '.Reservations[].Instances[].SecurityGroups[0].GroupId'`
sg1=`aws ec2 describe-instances --instance-ids $i | jq -r '.Reservations[].Instances[].SecurityGroups[1].GroupId'`
az=`aws ec2 describe-instances --instance-ids $i  | jq -r '.Reservations[].Instances[].Placement.AvailabilityZone'`
subid=`aws ec2 describe-instances --instance-ids $i  | jq -r '.Reservations[].Instances[].NetworkInterfaces[0].SubnetId'`
nn=`aws ec2 describe-instances --instance-ids $i  | jq -r '.Reservations[].Instances[].PrivateDnsName'`
echo ${az} $nn $subid
cat << EOF > ${az}-pod-netconfig2.yaml
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: ${az}-pod-netconfig2
spec:
 subnet: ${subid}
 securityGroups:
 - ${sg0}
EOF
kubectl apply -f ${az}-pod-netconfig2.yaml
kubectl annotate node ${nn} k8s.amazonaws.com/eniConfig=${az}-pod-netconfig2 --overwrite

done