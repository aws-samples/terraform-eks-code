cur=`pwd`
dirs="extra/eks-cidr2 extra/nodeg2 sample-app lb2 eks-cidr cicd nodeg cluster c9net iam net tf-setup"
for i in $dirs; do
cd $i
echo "Destroying in $i"
terraform destroy -auto-approve
rm -rf .terraform
cd $cur
done
exit