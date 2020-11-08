# SSM perm add to role - should bring nodes online in SSM
# get node instance role
resp=`aws eks  describe-nodegroup --cluster-name mycluster1 --nodegroup-name ng-maneksami2`
ir=`echo $resp | jq .nodegroup.nodeRole | cut -f2 -d'/' | tr -d '"'`
echo $ir
#add AmazonSSMManagedInstanceCore 
aws iam attach-role-policy --role-name $ir --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
#CloudWatchAgentServerPolicy  for prometheus/CW
aws iam attach-role-policy --role-name $ir --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
