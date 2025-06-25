resource "null_resource" "gen_backend" {
  triggers = {
    always_run = timestamp()
  }
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.terraform_state]
  provisioner "local-exec" {
    when    = create
    command = <<EOT
        sleep 6
        ./gen-backend.sh
    EOT
  }
}
