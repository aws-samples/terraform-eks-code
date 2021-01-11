cur=`pwd`
cd ../nodeg
terraform destroy -auto-approve
cd $cur
cd ../cluster
terraform destroy -auto-approve
cd $cur
cd ../c9net
terraform destroy -auto-approve
cd $cur
cd ../iam
terraform destroy -auto-approve
cd $cur
cd ../net
terraform destroy -auto-approve
cd $cur