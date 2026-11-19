# Istio Ingress Gateway Restart
# Restarts the ingress gateway deployment after Istio installation
# Ensures gateway picks up latest configuration and resolves race conditions
resource "terraform_data" "restart" {
  # Re-run only when the Istio version or cluster changes
  # (previously a null_resource with a timestamp() trigger, which restarted the gateway on every apply)
  triggers_replace = {
    istio_version = local.istio_chart_version
    cluster       = nonsensitive(data.aws_ssm_parameter.cluster-name.value)
  }
  # Wait for all Helm releases to complete
  depends_on = [module.eks_blueprints_addons.helm_release]
  # Execute restart command
  provisioner "local-exec" {
    on_failure  = fail # Fail Terraform if restart fails
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

moved {
  from = null_resource.restart
  to   = terraform_data.restart
}
# Why this is needed:
# - Istio components need time to fully initialize
# - Ingress gateway may start before control plane is ready
# - Restart ensures gateway has latest configuration
# - Prevents potential race conditions during installation
