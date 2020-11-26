#enable CNI custom networking
kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
# restart all nodes so they have aws_node with correct flag
# drqin node and SSM or SSH the commands ??
#
#
#add the ENIConfig label for identifying your worker nodes, run the following command:
kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=failure-domain.beta.kubernetes.io/zone
# Install ENIconfig CRD
export AZ1=$(echo $1)
export AZ2=$(echo $2)
export AZ3=$(echo $3)
export CUST_SNET1=$(echo $4)
export CUST_SNET2=$(echo $5)
export CUST_SNET3=$(echo $6)
echo "$AZ1 $AZ2 $AZ3"
echo "$CUST_SNET1 $CUST_SNET2 $CUST_SNET3"
cat << EOF | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: eniconfigs.crd.k8s.amazonaws.com
spec:
  scope: Cluster
  group: crd.k8s.amazonaws.com
  version: v1alpha1
  names:
    plural: eniconfigs
    singular: eniconfig
    kind: ENIConfig
EOF
#
#
#To create an ENIConfig custom resource for all subnets and Availability Zones, run the following commands:
cat <<EOF  | kubectl apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: $AZ1
spec:
  subnet: $CUST_SNET1
EOF

cat <<EOF | kubectl apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: $AZ2
spec:
  subnet: $CUST_SNET2
EOF

cat <<EOF | kubectl apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: $AZ3
spec:
  subnet: $CUST_SNET3
EOF


