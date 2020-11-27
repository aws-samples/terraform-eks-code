cur=`pwd`
dirs="tf-setup net iam c9net cluster nodeg eks-cidr lb2"
rdirs=$(echo $dirs | rev)
for i in $rdirs; do
cd $i
echo "Destroying in $i"
terraform destroy -auto-approve
rm -rf .terraform
cd $cur
done
exit