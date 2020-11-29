cur=`pwd`
dirs="cicd lb2 eks-cidr nodeg cluster c9net iam net tf-setup"
for i in $dirs; do
cd $i
echo "Destroying in $i"
rm -rf .terraform
terraform init
terraform destroy -auto-approve
rm -rf .terraform
cd $cur
done
exit