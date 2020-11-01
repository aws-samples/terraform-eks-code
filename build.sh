cd 01*
terraform init
terraform plan -out tfpan
terraform apply tfplan
cd ..
cd 02*
terraform init
terraform plan -out tfpan
terraform apply tfplan
cd ..
cd 03*
terraform init
terraform plan -out tfpan
terraform apply tfplan
cd ..
cd 04*
terraform init
terraform plan -out tfpan
terraform apply tfplan
./auth.sh
./test.sh
cd ..
cd 05*
terraform init
terraform plan -out tfpan
terraform apply tfplan
cd ..