resource "null_resource" "auth-cidr" {
triggers = {
    always_run = timestamp()
}
depends_on     = [aws_iam_role.codebuild-eks-cicd-build-app-service-role]
provisioner "local-exec" {
    on_failure  = fail
    when = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo "auth cicd role for K8s"
        ./auth-cicd.sh
        echo "************************************************************************************"
     EOT
}
}