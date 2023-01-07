test -n "$1" && echo CLUSTER is "$1" || "echo CLUSTER is not set && exit"
CLUSTER=$(echo $1)
test -n "$2" && echo tfid is "$2" || "echo tfid is not set && exit"
tfid=$(echo $2)
comm=`printf "kubectl get node --selector='eks.amazonaws.com/nodegroup==%s-ng1' -o json" $CLUSTER`
allnodes=`eval $comm`
len=`eval $comm | jq '.items | length-1'`
for i in `seq 0 $len`; do
nn=`echo $allnodes | jq ".items[(${i})].metadata.name" | tr -d '"'`
nz=`echo $allnodes | jq ".items[(${i})].metadata.labels" | grep failure | grep zone | cut -f2 -d':' | tr -d ' ' | tr -d ','| tr -d '"'`
echo $nn $nz $nr
echo "kubectl annotate node ${nn} k8s.amazonaws.com/eniConfig=${nz}-pod-netconfig --overwrite"
kubectl annotate node ${nn} k8s.amazonaws.com/eniConfig=${nz}-pod-netconfig --overwrite
done