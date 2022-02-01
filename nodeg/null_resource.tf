resource "null_resource" "gen_cluster_auth" {
triggers = {
    always_run = timestamp()
}
depends_on = [aws_eks_node_group.ng1]
provisioner "local-exec" {
    on_failure  = fail
    when = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        ./c9-auth.sh
        echo "************************************************************************************"
     EOT
}
}

  