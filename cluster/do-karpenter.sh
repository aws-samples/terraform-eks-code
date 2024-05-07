export CLUSTER_NAME=$(aws eks list-clusters --query clusters[0] | tr -d '"')
export KAR_ROLE=$(aws iam list-roles --query Roles[].RoleName | grep Karpenter-eks-workshop | tr -d ' |"|,')
envsubst < karpenter-node_class.yaml | kubectl apply -f -
envsubst < karpenter-node_pool.yaml | kubectl apply -f -
