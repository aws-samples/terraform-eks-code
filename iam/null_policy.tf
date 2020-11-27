resource "null_resource" "policy" {
triggers = {
    always_run = "${timestamp()}"
}
provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
            curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
            printf "data \"aws_iam_policy_document\" \"example\" {\n" > aws_iam_policy_document.tf
            cat iam-policy.json >> aws_iam_policy_document.tf
            printf "}\n" >> aws_iam_policy_document.tf  
            ls aws_iam_policy_document.tf
            #cat aws_iam_policy_document.tf
            cp -v aws_iam_policy_document.tf ../lb2
     EOT
}
}