resource "null_resource" "destroy" {
depends_on=[aws_iam_policy.load-balancer-policy]
triggers = {
       always_run = timestamp()
}
provisioner "local-exec" {
    on_failure  = fail
    when    = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo "Remove helm deployment"
        helm delete aws-load-balancer-controller -n kube-system
        echo "Remove CRD"
        kubectl delete -f crds.yaml 
        echo "done"
     EOT
}
}