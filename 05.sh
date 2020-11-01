cd 05*
terraform init
terraform plan -out tfplan
terraform apply tfplan
cd ..