resource "null_resource" "auth_cluster" {
triggers = {
    always_run = "${timestamp()}"
}
depends_on = [data.aws_eks_cluster.eks_cluster]
provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo -e "\x1B[31m Warning! Checking Authorization ${data.aws_eks_cluster.eks_cluster.name}...should see Server Version: v1.17.xxx \x1B[0m"
        ./auth.sh ${data.aws_eks_cluster.eks_cluster.name}
        echo "************************************************************************************"
     EOT
}
}

  