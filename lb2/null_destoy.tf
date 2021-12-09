resource "null_resource" "destroy" {
depends_on=[aws_iam_policy.load-balancer-policy]
triggers = {
       always_run = timestamp()
}
provisioner "local-exec" {
    on_failure  = continue
    when    = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        #echo "Remove helm deployment"
        #helm delete aws-load-balancer-controller -n kube-system
        if [ -f "crds.yml" ]; then
        echo "Set context"
        arn=$(terraform state show data.aws_eks_cluster.eks_cluster | grep arn | grep :cluster | cut -f2 -d'=' | jq -r .)
        echo $arn
        kubectx $arn
        echo "Remove CRD"
        kubectl delete -f crds.yaml 
        echo "done"
        fi
     EOT
}
}