
# Step 1 - done in cluster create
#eksctl utils associate-iam-oidc-provider   --region $1 --cluster $2  --approve
# Step 2 download policy JSON
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
# Step 3 create the Load Balancer policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json
# Step 4 Create IAM role for servioce account aws-load-balancer-controller
eksctl create iamserviceaccount --cluster mycluster1 --namespace=kube-system \
--name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::566972129213:policy/AWSLoadBalancerControllerIAMPolicy --approve
#helm repo add eks https://aws.github.io/eks-charts
# Step 5 - should return not found - no old alb-ingress controller
# kubectl get deployment -n kube-system alb-ingress-controller
#
# Step 6 install CRD & helm - doing step 7 instead
#rm -f crds.yaml*
#wget https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml
#kubectl apply -f crds.yaml
#kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
#helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$2 --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set image.repository=602401143452.dkr.ecr.$1.amazonaws.com/amazon/aws-load-balancer-controller
#helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$2 --set serviceAccount.name=aws-load-balancer-controller --set image.repository=602401143452.dkr.ecr.$1.amazonaws.com/amazon/aws-load-balancer-controller --set image.tag="v2.1.0"
#
# Step 7 
# Install cert mgr
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.2/cert-manager.yaml
# install controller
rm -f v2_1_0_full.yaml
curl -o v2_1_0_full.yaml https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/v2_1_0_full.yaml
kubectl apply -f v2_1_0_full.yaml

# check it
kubectl get deployment -n kube-system aws-load-balancer-controller