kubectl get configmap -n kube-system aws-auth -o yaml > aws-auth.yaml
cat << EoF >> aws-auth.yaml
data:
  mapUsers: |
    - userarn: arn:aws:iam::${ACCOUNT_ID}:assumed-role/TeamRole/MasterKey
      username: ee-master-role
      groups:
        - system:masters
EoF
kubectl apply -f aws-auth.yaml
