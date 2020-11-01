cd 04*
terraform init
terraform plan -out tfplan
terraform apply tfplan
./auth.sh
./test.sh
cd ..
