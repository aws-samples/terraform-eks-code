resource "null_resource" "sleep" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    depends_on=[module.eks_blueprints_addons.aws_load_balancer_controller]
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        sleep 45
     EOT
  }
}