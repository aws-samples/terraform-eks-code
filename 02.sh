cd 02*
terraform init
terraform plan -out tfplan
terraform apply tfplan
cd ..
