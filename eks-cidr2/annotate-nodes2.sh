test -n "$7" && echo CLUSTER is "$7" || "echo CLUSTER is not set && exit"
zone1=$(echo $1)
zone2=$(echo $2)
zone3=$(echo $3)
sub1=$(echo $4)
sub2=$(echo $5)
sub3=$(echo $6)
CLUSTER=$(echo $7)
kubectl get crd
# get the SG's
INSTANCE_IDS=(`aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters "Name=tag-key,Values=eks:nodegroup-name" "Name=tag-value,Values=ng2-mycluster1" "Name=instance-state-name,Values=running" --output text`)
for i in "${INSTANCE_IDS[0]}"
do
echo "Descr EC2 instance $i ..."
sg0=`aws ec2 describe-instances --instance-ids $i | jq -r '.Reservations[].Instances[].SecurityGroups[0].GroupId'`
sg1=`aws ec2 describe-instances --instance-ids $i | jq -r '.Reservations[].Instances[].SecurityGroups[1].GroupId'`
done
echo "subnet $sub1 zone $zone1"
echo "subnet $sub2 zone $zone2"
echo "subnet $sub3 zone $zone3"

echo ${zone1}
cat << EOF > ${zone1}-pod-netconfig2.yaml
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: ${zone1}-pod-netconfig2
spec:
 subnet: ${sub1}
 securityGroups:
 - ${sg0}
EOF
echo "cat ${zone1}-pod-netconfig2.yaml"
cat ${zone1}-pod-netconfig2.yaml
#

echo ${zone2}
cat << EOF > ${zone2}-pod-netconfig2.yaml
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: ${zone2}-pod-netconfig2
spec:
 subnet: ${sub2}
 securityGroups:
 - ${sg0}
EOF

echo "cat ${zone2}-pod-netconfig2.yaml"
cat ${zone2}-pod-netconfig2.yaml
#
echo ${zone3}
cat << EOF > ${zone3}-pod-netconfig2.yaml
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: ${zone3}-pod-netconfig2
spec:
 subnet: ${sub3}
 securityGroups:
 - ${sg0}
EOF
echo "cat ${zone3}-pod-netconfig2.yaml"
cat ${zone3}-pod-netconfig2.yaml

echo "apply the CRD ${zone1}"
kubectl apply -f ${zone1}-pod-netconfig2.yaml
echo "apply the CRD ${zone2}"
kubectl apply -f ${zone2}-pod-netconfig2.yaml
echo "apply the CRD ${zone3}"
kubectl apply -f ${zone3}-pod-netconfig2.yaml
allnodes=`kubectl get node --selector='eks.amazonaws.com/nodegroup==ng2-mycluster1' -o json`
len=`kubectl get node --selector='eks.amazonaws.com/nodegroup==ng2-mycluster1' -o json | jq '.items | length-1'`
for i in `seq 0 $len`; do
nn=`echo $allnodes | jq ".items[(${i})].metadata.name" | tr -d '"'`
nz=`echo $allnodes | jq ".items[(${i})].metadata.labels" | grep failure | grep zone | cut -f2 -d':' | tr -d ' ' | tr -d ','| tr -d '"'`
echo $nn $nz $nr
echo "kubectl annotate node ${nn} k8s.amazonaws.com/eniConfig=${nz}-pod-netconfig2"
kubectl annotate node ${nn} k8s.amazonaws.com/eniConfig=${nz}-pod-netconfig2
done

