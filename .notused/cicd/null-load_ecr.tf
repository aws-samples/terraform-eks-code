resource "null_resource" "load_ecr" {
  triggers = {
    always_run = timestamp()
  }
  #depends_on = [aws_ecr_repository.busybox]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        ./load_ecr.sh ${var.karpenter_version}
        echo "************************************************************************************"
     EOT
  }
}