cd 01*
terraform init
terraform plan -out tfpan
terraform apply tfplan
cd ..
