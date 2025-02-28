export CLUSTER_NAME=mgmt-workshop
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
cat << EOF > edns_values.yaml
image:
  tag: v0.11.0
provider: aws
registry: txt
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${ACCOUNT_ID}:role/keycloak-blog-external-dns
txtOwnerId: $CLUSTER_NAME
EOF

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm install external-dns external-dns/external-dns \
    --create-namespace \
    --namespace external-dns \
    -f edns_values.yaml