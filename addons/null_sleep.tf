# Synchronization Delay
# Adds a delay between add-on installations to prevent race conditions
# Ensures load balancer controller is fully initialized before External DNS

resource "null_resource" "sleep" {
  # Always run on apply (timestamp changes every time)
  triggers = {
    always_run = timestamp() 
  }
  
  # Wait for load balancer controller to be installed
  # Note: This dependency is on a module output that may not exist if LB controller is disabled
  depends_on = [module.eks_blueprints_addons.aws_load_balancer_controller]
  
  # Execute sleep command
  provisioner "local-exec" {
    on_failure  = fail  # Fail Terraform if sleep fails
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        sleep 20
     EOT
  }
}

# Why this is needed:
# - Load balancer controller creates webhooks
# - Webhooks need time to become ready
# - External DNS depends on these webhooks
# - 20-second delay ensures stability