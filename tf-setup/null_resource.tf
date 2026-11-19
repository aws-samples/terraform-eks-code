# Backend Configuration Generator
# Runs gen-backend.sh after the S3 bucket is ready
# The script generates backend.tf files for all subsequent stages
resource "terraform_data" "gen_backend" {
  # Re-run only when the state bucket, region or the generator script changes
  # (previously a null_resource with a timestamp() trigger, which ran on every apply)
  triggers_replace = {
    bucket = aws_s3_bucket.terraform_state.bucket
    region = var.region
    script = filesha256("${path.module}/gen-backend.sh")
  }
  # Wait for S3 bucket encryption to be fully configured
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.terraform_state]
  # Execute the backend generation script
  # Note: 6-second sleep allows AWS to propagate S3 bucket configuration
  provisioner "local-exec" {
    when    = create
    command = <<EOT
        sleep 6
        ./gen-backend.sh
    EOT
  }
}

moved {
  from = null_resource.gen_backend
  to   = terraform_data.gen_backend
}
