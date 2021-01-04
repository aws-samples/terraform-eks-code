resource "null_resource" "cleanup" {
triggers = {
    always_run = timestamp()
}
depends_on     = [aws_iam_role.codebuild-eks-cicd-build-app-service-role]
provisioner "local-exec" {
    on_failure  = fail
    when = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo "remote git credentials &" sample app
        ./cleanup.sh
        echo "************************************************************************************"
     EOT
}
}