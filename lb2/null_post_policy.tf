resource "null_resource" "post-policy" {
depends_on=[aws_iam_policy.load-balancer-policy]
triggers = {
    always_run = "${timestamp()}"
}
provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        eksctl utils associate-iam-oidc-provider   --region $AWS_REGION --cluster mycluster1  --approve
        # helm chart does this if you let it
        eksctl create iamserviceaccount --cluster mycluster1 --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::566972129213:policy/AWSLoadBalancerControllerIAMPolicy --approve
        #helm repo add eks https://aws.github.io/eks-charts

        kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

        helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=mycluster1 --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set image.repository=602401143452.dkr.ecr.eu-west-1.amazonaws.com/amazon/aws-load-balancer-controller 

     EOT
}
}