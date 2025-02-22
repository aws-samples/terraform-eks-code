echo "irsa test"
CLUSTER="eks-workshop"
OIDC=$(aws eks describe-cluster --name $CLUSTER --query "cluster.identity.oidc.issuer" --output text)
echo $OIDC
oid=$(echo $OIDC | cut -f5 -d'/')
aws iam list-open-id-connect-providers --output text | grep $oid
if [[ $? -eq 0 ]];then
echo "oidc provider exists"
fi

