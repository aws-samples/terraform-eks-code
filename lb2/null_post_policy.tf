resource "null_resource" "post-policy" {
depends_on=[aws_iam_policy.load-balancer-policy]
triggers = {
    always_run = "${timestamp()}"
}
provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        #reg=${data.aws_eks_cluster.eks_cluster.arn}
        #echo $reg
        #reg=$(echo ${data.aws_eks_cluster.eks_cluster.arn} | cut -f4 -d':')
        #acc=$(echo ${data.aws_eks_cluster.eks_cluster.arn} | cut -f5 -d':')
        #cn=$(echo ${data.aws_eks_cluster.eks_cluster.name})
        #echo "$reg $cn $acc"
        ./post-policy.sh eu-west-1 mycluster1 556972129213
     EOT
}
}