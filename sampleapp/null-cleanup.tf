resource "null_resource" "cleanup" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    on_failure  = fail
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo "remote git credentials &" sample app
        ./cleanup.sh
        echo "************************************************************************************"
     EOT
  }
}