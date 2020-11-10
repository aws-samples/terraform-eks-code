cd net
terraform init
terraform plan -out tfpan
terraform apply tfplan
cd ..
cd iam
terraform init
terraform plan -out tfpan
terraform apply tfplan
cd ..
cd c9net
terraform init
terraform plan -out tfpan
terraform apply tfplan
cd ..
cd cluster
terraform init
terraform plan -out tfpan
terraform apply tfplan
cd ..
cd nodeg
terraform init
terraform plan -out tfpan
terraform apply tfplan
cd ..