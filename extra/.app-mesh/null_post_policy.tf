resource "null_resource" "post-policy" {
depends_on=[aws_iam_policy.appmesh-policy]
triggers = {
    always_run = timestamp()
}
provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    when = create
    command     = <<EOT
        rm -f crds.yaml*
        curl -o crds.yaml https://raw.githubusercontent.com/aws/eks-charts/master/stable/appmesh-controller/crds/crds.yaml
        kubectl apply -f crds.yaml
        #echo "done"
     EOT
}
}