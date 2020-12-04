allnodes=`kubectl get node --selector='eks.amazonaws.com/nodegroup==ng1-mycluster1' -o json`
len=`kubectl get node --selector='eks.amazonaws.com/nodegroup==ng1-mycluster1' -o json | jq '.items | length-1'`
for i in `seq 0 $len`; do
nn=`echo $allnodes | jq ".items[(${i})].metadata.name" | tr -d '"'`
nz=`echo $allnodes | jq ".items[(${i})].metadata.labels" | grep failure | grep zone | cut -f2 -d':' | tr -d ' ' | tr -d ','| tr -d '"'`
echo $nn $nz $nr
echo "kubectl annotate node ${nn} k8s.amazonaws.com/eniConfig=${nz}-pod-netconfig"
kubectl annotate node ${nn} k8s.amazonaws.com/eniConfig=${nz}-pod-netconfig
done

