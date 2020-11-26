#enable CNI custom networking
kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
kubectl describe daemonset aws-node -n kube-system | grep -A5 Environment
# restart all nodes so they have aws_node with correct flag
# drqin node and SSM or SSH the commands ??
#
#
#add the ENIConfig label for identifying your worker nodes, run the following command:
kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=failure-domain.beta.kubernetes.io/zone
# Install ENIconfig CRD
