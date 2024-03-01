resource "null_resource" "restart" {
  triggers = {
    always_run = timestamp()
  }
  depends_on = [module.eks_blueprints_addons.helm_release]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
       sleep 35
       kubectl rollout restart deployment istio-ingress -n istio-ingress
       sleep 10
     EOT
  }
}