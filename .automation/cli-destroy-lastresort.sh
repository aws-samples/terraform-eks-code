echo "Pass 2 cli based actions ..."
accid=$(aws --output json sts get-caller-identity | jq -r '.Account' )
lbarn=$(printf "arn:aws:iam::%s:policy/AWSLoadBalancerControllerIAMPolicy" $accid)
aws iam delete-policy --policy-arn $lbarn || echo "no LB policy to delete"
aws dynamodb delete-table --table-name terraform_locks_net || echo "terraform_locks_net"
aws dynamodb delete-table --table-name terraform_locks_iam || echo "terraform_locks_iam"
aws dynamodb delete-table --table-name terraform_locks_c9net || echo "terraform_locks_c9net"
aws dynamodb delete-table --table-name terraform_locks_cluster || echo "terraform_locks_cluster"
aws dynamodb delete-table --table-name terraform_locks_nodeg || echo "terraform_locks_nodeg"
aws dynamodb delete-table --table-name terraform_locks_eks-cidr || echo "terraform_locks_eks-cidr"
aws dynamodb delete-table --table-name terraform_locks_sampleapp || echo "terraform_locks_sampleapp"
aws dynamodb delete-table --table-name terraform_locks_cicd || echo "terraform_locks_cicd"
buck=()
for j in `aws s3 ls | awk '{print $3}' | grep codep-tfeks`; do 
echo $j
comm=$(printf "aws s3 rm s3://%s --recursive" $j)
aws s3api delete-objects --bucket ${j} --delete "$(aws s3api list-object-versions --bucket ${j} --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
aws s3api delete-objects --bucket ${j} --delete "$(aws s3api list-object-versions --bucket ${j} --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"
echo $comm
eval $comm
comm=$(printf "aws s3 rb s3://%s --force" $j)
echo $comm
eval $comm
done
buck=()
for j in `aws s3 ls | awk '{print $3}' | grep tf-state-`; do 
echo $j
comm=$(printf "aws s3 rm s3://%s --recursive" $j)
echo $comm
eval $comm
comm=$(printf "aws s3 rb s3://%s --force" $j)
echo $comm
eval $comm
done
