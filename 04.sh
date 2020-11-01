cd 04*
terraform init
terraform plan -out tfpan
terraform apply tfplan
./auth.sh
./test.sh
cd ..
