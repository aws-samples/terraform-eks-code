# get the default vpc id
vpcid=`aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[].VpcId" | jq .[0] | tr -d '"'` 
rtbid=`aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcid" "Name=association.main,Values=true" --query "RouteTables[0].RouteTableId" | tr -d '"'`
sgid=`aws ec2 describe-instances --filters "Name=vpc-id,Values=$vpcid" --query "Reservations[].Instances[].SecurityGroups[].GroupId" | jq .[] | tr -d '"'`
export TF_VAR_rtbid=$rtbid
export TF_VAR_sgid=$sgid
echo "TF_VAR_rtbid=$TF_VAR_rtbid"
echo "TF_VAR_sgid=$TF_VAR_sgid"

tsubid==`aws ec2 describe-subnets --filters "Name=cidr-block,Values=10.1.4.0/24" --query "Subnets[].SubnetId" | jq .[] | tr -d '"'` 
subid=`echo $tsubid | tr -d '='`
sgid2=`aws ec2 describe-instances --filters "Name=network-interface.subnet-id,Values=$subid" --query "Reservations[].Instances[].SecurityGroups[].GroupId" | jq .[] | tr -d '"'`
rtbid2=`aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$subid" --query "RouteTables[0].RouteTableId" | tr -d '"'`
#echo $rtbid2
export TF_VAR_rtbid_10_1=$rtbid2
export TF_VAR_sgid_10_1=$sgid2
echo "TF_VAR_rtbid_10_1=$TF_VAR_rtbid_10_1"
echo "TF_VAR_sgid_10_1=$TF_VAR_sgid_10_1"
terraform plan -out tfplan