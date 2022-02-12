resource "null_resource" "load_ecr" {
triggers = {
    always_run = timestamp()
}
depends_on = [aws_ecr_repository.busybox]
provisioner "local-exec" {
    on_failure  = fail
    when = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        docker pull public.ecr.aws/karpenter/controller:v${var.karpenter_version}
        docker tag public.ecr.aws/karpenter/controller:v${var.karpenter_version} $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/karpenter/controller
        docker pull public.ecr.aws/karpenter/webhook:v${var.karpenter_version}
        docker tag public.ecr.aws/karpenter/webhook:v${var.karpenter_version} $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/karpenter/webhook
        ./load_ecr.sh
        echo "************************************************************************************"
     EOT
}
}