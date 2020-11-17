cur=`pwd`
dirs="tf-setup net iam c9net cluster nodeg"
for i in $dirs; do
cd $i
echo "Building in $i"
terraform init -no-color
terraform plan -out tfplan -no-color
terraform apply tfplan -no-color
cd $cur
done
exit