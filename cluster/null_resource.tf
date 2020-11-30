resource "null_resource" "gen_backend" {
triggers = {
    always_run = "${timestamp()}"
}
depends_on = [aws_eks_cluster.mycluster1]
provisioner "local-exec" {
    on_failure  = fail
    when = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo -e "\x1B[32m Testing Network Connectivity ${aws_eks_cluster.mycluster1.name}...should see port 443/tcp open  https\x1B[0m"
        ./test.sh ${aws_eks_cluster.mycluster1.name}
        echo -e "\x1B[32m Checking Authorization ${aws_eks_cluster.mycluster1.name}...should see Server Version: v1.17.xxx \x1B[0m"
        ./auth.sh ${aws_eks_cluster.mycluster1.name}
        #kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
        #kubectl describe daemonset aws-node -n kube-system | grep -A5 Environment | grep CUSTOM
        echo "************************************************************************************"
     EOT
}
}

  