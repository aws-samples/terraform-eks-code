resource "null_resource" "gen_backend" {
triggers = {
    always_run = "${timestamp()}"
}
depends_on = [aws_eks_cluster.mycluster1]
provisioner "local-exec" {
    on_failure  = "fail"
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo -e "\x1B[31m Warning! Testing Network Connectivity ${aws_eks_cluster.mycluster1.name}...should see port 443/tcp open \x1B[0m"
        ./test.sh
        echo -e "\x1B[31m Warning! Checking Authorization ${aws_eks_cluster.mycluster1.name}...should see Server Version \x1B[0m"
        ./auth.sh
        echo "************************************************************************************"
     EOT
}
}

  