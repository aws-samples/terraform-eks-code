t2=`date +%s%N`
t1=`hostname | cut -f1 -d'.'`
bucket_name=`printf "terraform-state-%s-%s" $t1 $t2 | awk '{print tolower($0)}'`
terraform init
terraform plan -var="bucket_name=$bucket_name" -out tfplan
terraform apply tfplan
#./gen-backend.sh
