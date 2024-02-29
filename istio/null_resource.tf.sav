resource "null_resource" "restart" {
  triggers = {
    always_run = timestamp()
  }
  depends_on = [eks_blueprints_addons.istio]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
       kubectl rollout restart deployment istio-ingress -n istio-ingress
     EOT
  }
}