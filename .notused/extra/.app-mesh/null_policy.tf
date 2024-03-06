resource "null_resource" "policy" {
depends_on=[kubernetes_namespace.appmesh-system]
triggers = {
    always_run = timestamp()
}
provisioner "local-exec" {
    on_failure  = fail
    when = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        curl -o iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json
     EOT
}
}