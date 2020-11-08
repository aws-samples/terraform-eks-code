CLOUD9_NAME="cloud9-eksworkshop"
CLUSTER="eksworkshop-eksctl"

resp=`aws eks describe-cluster --name $CLUSTER`
vpcid=`echo $resp | jq .cluster.resourcesVpcConfig.vpcId | tr -d '"'`

resp=`aws ec2 describe-instances --filter Name=tag:Name,Values=*${CLOUD9_NAME}*`
c9vpcid=`echo $resp | jq .Reservations[0].Instances[0].VpcId | tr -d '"'`

echo "peering"
aws ec2 create-vpc-peering-connection --vpc-id $vpcid --peer-vpc-id $c9vpcid
sleep 10
pid=`aws ec2 describe-vpc-peering-connections | jq .VpcPeeringConnections[0].VpcPeeringConnectionId | tr -d '"'` 
echo $pid
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $pid


