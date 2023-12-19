resource "null_resource" "sleep" {
  triggers = {
    always_run = timestamp() 
  }
  depends_on=[module.eks_blueprints_addons.aws_load_balancer_controller]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        sleep 10
     EOT
  }
}