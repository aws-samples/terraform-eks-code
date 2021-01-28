resource "null_resource" "gen_cluster_auth" {
triggers = {
    always_run = timestamp()
}
depends_on = [aws_eks_cluster.cluster]
provisioner "local-exec" {
    on_failure  = fail
    when = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo -e "\x1B[32m Testing Network Connectivity ${aws_eks_cluster.cluster.name}...should see port 443/tcp open  https\x1B[0m"
        ./test.sh ${aws_eks_cluster.cluster.name}
        echo -e "\x1B[32m Checking Authorization ${aws_eks_cluster.cluster.name}...should see Server Version: v1.18.xxx \x1B[0m"
        ./auth.sh ${aws_eks_cluster.cluster.name}
        echo "************************************************************************************"
     EOT
}
}

  