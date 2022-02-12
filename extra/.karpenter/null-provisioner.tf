resource "null_resource" "provisioner" {
  triggers = {
    iam_role_arn = helm_release.karpenter.arn
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