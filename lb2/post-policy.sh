test -n "$1" && echo REGION is "$1" || "echo REGION is not set && exit"
test -n "$2" && echo CLUSTER is "$2" || "echo CLUSTER is not set && exit"
test -n "$3" && echo ACCOUNT is "$3" || "echo ACCOUNT is not set && exit"
eksctl utils associate-iam-oidc-provider   --region $1 --cluster $2  --approve
eksctl create iamserviceaccount --cluster mycluster1 --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::$3:policy/AWSLoadBalancerControllerIAMPolicy --approve
#helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$2 --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set image.repository=602401143452.dkr.ecr.$1.amazonaws.com/amazon/aws-load-balancer-controller
sleep 3
kubectl get pods -A  | grep aws-load-balancer-controller