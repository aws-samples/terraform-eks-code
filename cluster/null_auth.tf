resource "null_resource" "gen_cluster_auth" {
  triggers = {
    always_run = timestamp()
  }
  #depends_on = [aws_eks_cluster.cluster]
  depends_on = [module.eks]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        CLUSTER_NAME=$(echo ${var.CLUSTER1_NAME})
        echo "Cluster name = $CLUSTER_NAME"
        aws eks update-kubeconfig --name $CLUSTER_NAME
        #eksctl utils write-kubeconfig --cluster $CLUSTER_NAME
        #context=$(kubectl config get-contexts -o name | grep $CLUSTER_NAME)
        ##kubectl config rename-context $context $CLUSTER_NAME
        kubectl version && kubectl get nodes
     EOT
  }
}

