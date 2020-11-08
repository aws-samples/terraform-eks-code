CLOUD9_NAME="cloud9-eksworkshop"
CLUSTER="eksworkshop-eksctl"

resp=`aws eks describe-cluster --name $CLUSTER`
vpcid=`echo $resp | jq .cluster.resourcesVpcConfig.vpcId | tr -d '"'`
sgid=`echo $resp | jq .cluster.resourcesVpcConfig.securityGroupIds[0] | tr -d '"'`
csgid=`echo $resp | jq .cluster.resourcesVpcConfig.clusterSecurityGroupId | tr -d '"'`

resp=`aws ec2 describe-instances --filter Name=tag:Name,Values=*${CLOUD9_NAME}*`
c9vpcid=`echo $resp | jq .Reservations[0].Instances[0].VpcId | tr -d '"'`
c9sg=`echo $resp | jq .Reservations[0].Instances[0].NetworkInterfaces[0].Groups[0].GroupId | tr -d '"'`

aws ec2 authorize-security-group-ingress --group-id $sgid --source-group $c9sg --protocol -1
aws ec2 authorize-security-group-ingress --group-id $csgid --source-group $c9sg --protocol -1
aws ec2 authorize-security-group-ingress --group-id $c9sg --source-group $sgid --protocol -1
