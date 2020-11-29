cur=`pwd`
dirs="nodeg eks-cidr lb2"
for i in $dirs; do
cd $i
echo "Building in $i"
rm -rf .terraform
terraform init -no-color
terraform plan -out tfplan -no-color
terraform apply tfplan -no-color
cd $cur
done
exit