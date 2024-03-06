resource "null_resource" "destroy" {
depends_on=[aws_iam_policy.appmesh-policy]
triggers = {
       always_run = timestamp()
}
provisioner "local-exec" {
    on_failure  = continue
    when    = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        #echo "Remove helm deployment"
        #helm delete aws-appmesh-controller -n kube-system
        if [ -f "crds.yml" ]; then
        echo "Remove CRD"
        kubectl delete -f crds.yaml 
        echo "done"
        fi
     EOT
}
}