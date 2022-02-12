resource "null_resource" "provisioner" {
  triggers = {
    cluster      = var.cluster-name
  }

  depends_on = [
    helm_release.karpenter
  ]

  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
            #kubectl apply -f default-provisioner.yaml      
        EOT
  }
}