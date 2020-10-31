cn=`terraform output cluster-name`
aws eks update-kubeconfig --name $cn
kubectx
