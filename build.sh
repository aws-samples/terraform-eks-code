cur=`pwd`
dirs="tf-setup net"
for i in $dirs; do
cd $i
pwd
cd $cur
done
exit

cd ..
terraform init -no-color
terraform plan -out tfplan -no-color
terraform apply tfplan -no-color
cd net
terraform init
terraform plan -out tfplan
terraform apply tfplan
cd ..
cd iam
terraform init
terraform plan -out tfplan
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