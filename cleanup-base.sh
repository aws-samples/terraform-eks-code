cd tf-setup
buck=$(aws s3 ls | grep terraform-state | awk '{print $3}')
terraform destroy -auto-approve -var="bucket_name=$buck"
cd ..
