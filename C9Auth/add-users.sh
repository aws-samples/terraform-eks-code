kubectl access-matrix -n my-project-dev --as eksworkshop-admin
kubectl get configmap -n kube-system aws-auth -o yaml > aws-auth.yaml
echo "add to yaml:"
echo ""
echo "  mapUsers: | "
echo "    - userarn:  arn:aws:iam::566972129213:user/andyt530"
echo "      username: andyt530"
echo "      groups: "
echo "        - system:masters"

kubectl apply -f aws-auth.yaml

aws eks update-kubeconfig --name ateks1