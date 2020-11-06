cd nodeg/init
terraform destroy -auto-approve
cd ../..
cd cluster/init
terraform destroy -auto-approve
cd ../..
cd c9net/init
terraform destroy -auto-approve
cd ../..
cd iam/init
terraform destroy -auto-approve
cd ../..
cd network
terraform destroy -auto-approve
cd ../..