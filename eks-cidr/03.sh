nc=`aws eks list-clusters | jq '.clusters | length'`
if [ $nc == 1 ] ; then
export CLUSTER=`aws eks list-clusters | jq '.clusters[0]' | tr -d '"'`
echo "EKS Cluster = $CLUSTER"
else
echo "Please set the environment variable CLUSTER"
exit
fi
kubectl get crd
# get the SG's
INSTANCE_IDS=(`aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=$CLUSTER" "Name=instance-state-name,Values=running" --output text`)
for i in "${INSTANCE_IDS[0]}"
do
echo "Descr EC2 instance $i ..."
sg0=`aws ec2 describe-instances --instance-ids $i | jq -r '.Reservations[].Instances[].SecurityGroups[0].GroupId'`
sg1=`aws ec2 describe-instances --instance-ids $i | jq -r '.Reservations[].Instances[].SecurityGroups[1].GroupId'`
done
echo "creating custom netwoking resource yaml's"
sub1=`aws ec2 describe-subnets  --filters "Name=cidr-block,Values=100.64.*18" --query 'Subnets[0].SubnetId' | tr -d '"'`
sub2=`aws ec2 describe-subnets  --filters "Name=cidr-block,Values=100.64.*18" --query 'Subnets[1].SubnetId'| tr -d '"'`
sub3=`aws ec2 describe-subnets  --filters "Name=cidr-block,Values=100.64.*18" --query 'Subnets[2].SubnetId' | tr -d '"'`
zone1=`aws ec2 describe-subnets  --filters "Name=cidr-block,Values=100.64.*18" --query 'Subnets[0].AvailabilityZone'| tr -d '"'`
zone2=`aws ec2 describe-subnets  --filters "Name=cidr-block,Values=100.64.*18" --query 'Subnets[1].AvailabilityZone'| tr -d '"'`
zone3=`aws ec2 describe-subnets  --filters "Name=cidr-block,Values=100.64.*18" --query 'Subnets[2].AvailabilityZone'| tr -d '"'`
echo "subnet $sub1 zone $zone1"
echo "subnet $sub2 zone $zone2"
echo "subnet $sub3 zone $zone3"
cat << EOF > ${zone1}-pod-netconfig.yaml
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: ${zone1}-pod-netconfig
spec:
 subnet: ${sub1}
 securityGroups:
 - ${sg0}
EOF
echo "cat ${zone1}-pod-netconfig.yaml"
cat ${zone1}-pod-netconfig.yaml
#

cat << EOF > ${zone2}-pod-netconfig.yaml
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: ${zone2}-pod-netconfig
spec:
 subnet: ${sub2}
 securityGroups:
 - ${sg0}
EOF 

echo "cat ${zone2}-pod-netconfig.yaml"
cat ${zone2}-pod-netconfig.yaml
#
cat << EOF > ${zone3}-pod-netconfig.yaml
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: ${zone3}-pod-netconfig
spec:
 subnet: ${sub3}
 securityGroups:
 - ${sg0}
EOF
echo "cat ${zone3}-pod-netconfig.yaml"
cat ${zone3}-pod-netconfig.yaml
echo "apply the CRD's"
kubectl apply -f ${zone1}-pod-netconfig.yaml
kubectl apply -f ${zone2}-pod-netconfig.yaml
kubectl apply -f ${zone3}-pod-netconfig.yaml
allnodes=`kubectl get nodes -o json`
len=`kubectl get nodes -o json | jq '.items | length-1'`
for i in `seq 0 $len`; do
nn=`echo $allnodes | jq ".items[(${i})].metadata.name" | tr -d '"'`
nz=`echo $allnodes | jq ".items[(${i})].metadata.labels" | grep failure | grep zone | cut -f2 -d':' | tr -d ' ' | tr -d ','| tr -d '"'`
echo $nn $nz $nr
echo "kubectl annotate node ${nn} k8s.amazonaws.com/eniConfig=${nz}-pod-netconfig"
kubectl annotate node ${nn} k8s.amazonaws.com/eniConfig=${nz}-pod-netconfig
done

