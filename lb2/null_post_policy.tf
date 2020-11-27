resource "null_resource" "post-policy" {
depends_on=[aws_iam_policy.load-balancer-policy]
triggers = {
    always_run = "${timestamp()}"
}
provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        carn=$(echo ${data.aws_eks_cluster.eks_cluster.arn})
        reg=$(echo $carn | cut -f4 -d':')
        acc=$(echo $carn | cut -f5 -d':')
        echo "$reg $acc"
        eksctl utils associate-iam-oidc-provider   --region $reg --cluster ${data.aws_eks_cluster.eks_cluster.name}  --approve
        # helm chart does this if you let it
        eksctl create iamserviceaccount --cluster mycluster1 --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::${acc}:policy/AWSLoadBalancerControllerIAMPolicy --approve
        #helm repo add eks https://aws.github.io/eks-charts

        kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

        helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=${data.aws_eks_cluster.eks_cluster.name} --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set image.repository=602401143452.dkr.ecr.${reg}.amazonaws.com/amazon/aws-load-balancer-controller 

     EOT
}
}