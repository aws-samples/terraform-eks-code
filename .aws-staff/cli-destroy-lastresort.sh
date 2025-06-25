echo "Pass 2 cli based actions ..."

accid=$(aws --output json sts get-caller-identity | jq -r '.Account' )
lbarn=$(printf "arn:aws:iam::%s:policy/AWSLoadBalancerControllerIAMPolicy" $accid)
aws logs delete-log-group --log-group-name /aws/eks/eks-workshop/cluster
aws kms delete-alias --alias-name alias/eks/eks-workshop
#arn:aws:iam::566972129213:policy/AmazonEKS_CNI_IPv6_Policy
aws iam delete-policy --policy-arn arn:aws:iam::$accid:policy/AmazonEKS_CNI_IPv6_Policy
aws iam delete-policy --policy-arn $lbarn || echo "no LB policy to delete"
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
