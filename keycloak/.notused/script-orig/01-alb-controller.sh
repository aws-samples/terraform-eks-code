export CLUSTER_NAME=mgmt-workshop
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
cat << EOF > aws_lb_values.yaml
clusterName: $CLUSTER_NAME
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${ACCOUNT_ID}:role/keycloak-blog-aws-lb-controller
image:
  tag: v2.4.1
EOF

helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
--create-namespace \
--namespace aws-lb \
-f aws_lb_values.yaml