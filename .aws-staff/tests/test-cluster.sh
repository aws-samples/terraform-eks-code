echo "cluster status"
aws eks describe-cluster --name eks-workshop --query 'cluster.status'
crds=$(kubectl get crds)
if [[ $crds == *"cninodes.eks"* ]]; then
    echo "cni is installed"
else
    echo "cni is not installed"
fi
if [[ $crds == *"ingressclassparams.eks"* ]]; then
    echo "ingressclassparams is installed"
else
    echo "ingressclassparams is not installed"
fi
if [[ $crds == *"nodeclasses.eks"* ]]; then
    echo "nodeclasse is installed"
else
    echo "nodeclasse is not installed"
fi
if [[ $crds == *"nodediagnostics.eks"* ]]; then
    echo "nodediagnostics is installed"
else
    echo "nodediagnostics is not installed"
fi
if [[ $crds == *"targetgroupbindings.eks"* ]]; then
    echo "targetgroupbindings is installed"
else
    echo "targetgroupbindings is not installed"
fi
if [[ $crds == *"securitygrouppolicies.vpcresources"* ]]; then
    echo "securitygrouppolicies is installed"
else
    echo "securitygrouppolicies is not installed"
fi
if [[ $crds == *"policyendpoints.networking"* ]]; then
    echo "policyendpoints is installed"
else
    echo "policyendpoints is not installed"
fi
storc=$(kubectl get storageclass)
if [[ $storc == *"ebs.csi.eks.amazonaws.com"* ]]; then
    echo "Auto mode ebs storageclass is active"
else
    echo "Auto mode ebs storageclass is not active"
fi
echo "csi drivers"
kubectl get csidriver
echo "nodeclass"
kubectl get nodeclass
echo "nodepool"
kubectl get nodepool

