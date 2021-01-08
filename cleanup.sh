cd nodeg
terraform destroy -auto-approve
cd ..
cd cluster
terraform destroy -auto-approve
cd ..
cd c9net
terraform destroy -auto-approve
cd ..
cd iam
terraform destroy -auto-approve
cd ..
cd net
terraform destroy -auto-approve
cd ..