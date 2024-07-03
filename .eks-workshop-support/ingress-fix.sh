# uninstall controller
#helm uninstall aws-load-balancer-controller -n kube-system
#sleep 5
# delete ingress kube-system
#kubectl delete ingress catalog -n catalog --ignore-not-found &
#kubectl delete ingress ui -n ui --ignore-not-found &
# manually reinstall ALB:
if [[ -z "${EKS_CLUSTER_NAME}" ]]; then
    export EKS_CLUSTER_NAME=$(eksctl get cluster | awk -F" " '{print $1}')
fi
export TF_VAR_eks_cluster_id="$EKS_CLUSTER_NAME"
if [[ -z "${LBC_ROLE_ARN}" ]]; then
    export LBC_ROLE_ARN=$(aws iam list-roles | jq -r '.Roles[] | select(.RoleName | contains("alb-controller-")).RoleName')
    echo "need LBC_ROLE_ARN"
fi
# Get this from ~/environment/eks-workshop/modules/exposing/ingress/.workshop/terraform/
if [[ -z "${LBC_CHART_VERSION}" ]]; then
    echo "need LBC_CHART_VERSION"
    export LBC_CHART_VERSION=$(grep default ~/environment/eks-workshop/modules/exposing/ingress/.workshop/terraform/vars.tf | cut -f2 -d'=' | tr -d ' |"')
fi
echo "LBC_CHART_VERSION: ${LBC_CHART_VERSION}"
echo "LBC_ROLE_ARN: ${LBC_ROLE_ARN}"
echo "EKS Cluster Name: ${EKS_CLUSTER_NAME}"
if [[ -z "${LBC_CHART_VERSION}" ]]; then
    echo "need LBC_CHART_VERSION"
    exit
fi
if [[ -z "${LBC_ROLE_ARN}" ]]; then
    echo "need LBC_ROLE_ARN"
    exit
fi
if [[ -z "${EKS_CLUSTER_NAME}" ]]; then
    echo "need EKS_CLUSTER_NAME"
    exit
fi
helm repo add eks-charts https://aws.github.io/eks-charts
helm upgrade --install aws-load-balancer-controller eks-charts/aws-load-balancer-controller \
    --version "${LBC_CHART_VERSION}" \
    --namespace "kube-system" \
    --set "clusterName=${EKS_CLUSTER_NAME}" \
    --set "serviceAccount.name=aws-load-balancer-controller-sa" \
    --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$LBC_ROLE_ARN" \
    --wait
