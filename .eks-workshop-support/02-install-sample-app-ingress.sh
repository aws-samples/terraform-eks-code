
helm repo add eks-charts https://aws.github.io/eks-charts
helm upgrade --install aws-load-balancer-controller eks-charts/aws-load-balancer-controller \
  --version "${LBC_CHART_VERSION}" \
  --namespace "kube-system" \
  --set "clusterName=${EKS_CLUSTER_NAME}" \
  --set "serviceAccount.name=aws-load-balancer-controller-sa" \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$LBC_ROLE_ARN" \
  --wait
kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/creating-ingress
sleep 2
kubectl get ingress ui -n ui
wait-for-lb $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")

