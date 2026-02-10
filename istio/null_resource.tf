# Istio Ingress Gateway Restart
# Restarts the ingress gateway deployment after Istio installation
# Ensures gateway picks up latest configuration and resolves race conditions

resource "null_resource" "restart" {
  # Always run on apply (timestamp changes every time)
  triggers = {
    always_run = timestamp()
  }
  
  # Wait for all Helm releases to complete
  depends_on = [module.eks_blueprints_addons.helm_release]
  
  # Execute restart command
  provisioner "local-exec" {
    on_failure  = fail  # Fail Terraform if restart fails
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
       # Wait for Istio components to stabilize
       sleep 35
       
       # Restart ingress gateway to pick up configuration
       kubectl rollout restart deployment istio-ingress -n istio-ingress
       
       # Wait for restart to complete
       sleep 10
     EOT
  }
}

# Why this is needed:
# - Istio components need time to fully initialize
# - Ingress gateway may start before control plane is ready
# - Restart ensures gateway has latest configuration
# - Prevents potential race conditions during installation