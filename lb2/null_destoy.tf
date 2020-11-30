resource "null_resource" "destroy" {
depends_on=[aws_iam_policy.load-balancer-policy]
triggers = {
       always_run = "${timestamp()}"
}
provisioner "local-exec" {
    on_failure  = fail
    when    = "destroy"
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        #reg=$(echo ${data.aws_eks_cluster.eks_cluster.arn} | cut -f4 -d':')
        #acc=$(echo ${data.aws_eks_cluster.eks_cluster.arn} | cut -f5 -d':')
        #cn=$(echo ${data.aws_eks_cluster.eks_cluster.name})
        #echo "$reg $cn $acc"
        ./cleanup.sh $reg $cn $acc
        echo "done"
     EOT
}
}