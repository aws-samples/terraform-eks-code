# Kubectl Configuration Automation
# Automatically configures kubectl access after cluster creation
# Enables Terraform to interact with the cluster for subsequent operations

resource "null_resource" "gen_cluster_auth" {
  # Always run on apply (timestamp changes every time)
  triggers = {
    always_run = timestamp()
  }
  
  # Wait for EKS cluster to be fully created
  depends_on = [module.eks]
  
  # Execute kubectl configuration script
  provisioner "local-exec" {
    on_failure  = fail  # Fail Terraform if script fails
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        CLUSTER_NAME=$(echo ${nonsensitive(data.aws_ssm_parameter.tf-eks-cluster-name.value)})
        echo "Cluster name = $CLUSTER_NAME"
        
        # Update kubeconfig with cluster credentials
        aws eks update-kubeconfig --name $CLUSTER_NAME
        
        # Alternative: eksctl method (commented out)
        #eksctl utils write-kubeconfig --cluster $CLUSTER_NAME
        
        # Rename context (optional, commented out)
        #context=$(kubectl config get-contexts -o name | grep $CLUSTER_NAME)
        #kubectl config rename-context $context $CLUSTER_NAME
        
        # Verify kubectl connectivity
        kubectl version
        
        # Wait for cluster to stabilize
        echo "sleep 10"
        sleep 10
    EOT
  }
}

