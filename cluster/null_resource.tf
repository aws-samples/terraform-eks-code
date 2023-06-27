resource "null_resource" "gen_cluster_auth" {
  triggers = {
    always_run = timestamp()
  }
  #depends_on = [aws_eks_cluster.cluster]
  depends_on = [aws_eks_addon.vpc-cni]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo -e "\x1B[32m Checking Authorization ${nonsensitive(aws_eks_cluster.cluster.name)} ...should see Server Version: v${var.eks_version}.xxx \x1B[0m"
        ./auth.sh ${nonsensitive(aws_eks_cluster.cluster.name)}
        echo "************************************************************************************"
     EOT
  }
}

  