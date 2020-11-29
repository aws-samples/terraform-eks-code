cur=`pwd`
dirs="lb2 eks-cidr nodeg"
for i in $dirs; do
cd $i
echo "Destroying in $i"
terraform destroy -auto-approve
rm -rf .terraform
cd $cur
done
exit