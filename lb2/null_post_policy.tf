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
        cn=$(echo ${data.aws_eks_cluster.eks_cluster.name})
        echo "$reg $cn $acc"
        ./post-policy.sh $reg $cn $acc
     EOT
}
}