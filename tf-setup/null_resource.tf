# Backend Configuration Generator
# This resource triggers the gen-backend.sh script after the S3 bucket is ready
# The script generates backend.tf files for all subsequent stages

resource "null_resource" "gen_backend" {
  # Always run on apply (timestamp changes every time)
  triggers = {
    always_run = timestamp()
  }
  
  # Wait for S3 bucket encryption to be fully configured
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.terraform_state]
  
  # Execute the backend generation script
  # Note: 6-second sleep allows AWS to propagate S3 bucket configuration
  # Consider using a more robust wait mechanism for production
  provisioner "local-exec" {
    when    = create
    command = <<EOT
        sleep 6
        ./gen-backend.sh
    EOT
  }
}
