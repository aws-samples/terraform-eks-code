test -n "$C9_PID" && echo C9_PID is "$C9_PID" || (echo "C9_PID is not set - exit" && exit)
echo "local auth"
sleep 5
c9builder=$(aws cloud9 describe-environment-memberships --environment-id=$C9_PID | jq -r '.memberships[].userArn')
if echo ${c9builder} | grep -q user; then
	rolearn=${c9builder}
        echo Role ARN: ${rolearn}
elif echo ${c9builder} | grep -q assumed-role; then
        assumedrolename=$(echo ${c9builder} | awk -F/ '{print $(NF-1)}')
        rolearn=$(aws iam get-role --role-name ${assumedrolename} --query Role.Arn --output text) 
        echo Role ARN: ${rolearn}
fi
## need to Terraform this ?
cat << EOF > patch.yaml
data:
  mapUsers: |
    - userarn: ${rolearn}  
      username: admin
      groups:
        - system:masters
EOF
kubectl get configmap -n kube-system aws-auth -o yaml > aws-auth.yaml
cat patch.yaml >> aws-auth.yaml
kubectl apply -f aws-auth.yaml
