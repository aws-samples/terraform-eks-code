CLOUD9_NAME="cloud9-eksworkshop"
CLUSTER="eksworkshop-eksctl"

resp=`aws eks describe-cluster --name $CLUSTER`
vpcid=`echo $resp | jq .cluster.resourcesVpcConfig.vpcId | tr -d '"'`
ekscidr=`aws ec2 describe-vpcs --vpc-ids $vpcid | jq .Vpcs[0].CidrBlock | tr -d '"'`

resp=`aws ec2 describe-instances --filter Name=tag:Name,Values=*${CLOUD9_NAME}*`
c9vpcid=`echo $resp | jq .Reservations[0].Instances[0].VpcId | tr -d '"'`
c9cidr=`aws ec2 describe-vpcs --vpc-ids $c9vpcid | jq .Vpcs[0].CidrBlock | tr -d '"'`

pid=`aws ec2 describe-vpc-peering-connections | jq .VpcPeeringConnections[0].VpcPeeringConnectionId | tr -d '"'`

eksrt=()
echo "eks route tables"
rtresp=`aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpcid Name=association.main,Values=false`
eksrt+=(`echo $rtresp | jq .RouteTables[].RouteTableId | tr -d '"'`)
nc=${#eksrt[@]}
for t in ${eksrt[@]}; do
echo $t
aws ec2 create-route --route-table-id $t --destination-cidr-block $c9cidr --vpc-peering-connection-id $pid
done

c9rt=()
echo "c9 route tables"
rtresp=`aws ec2 describe-route-tables --filters Name=vpc-id,Values=$c9vpcid`
c9rt+=(`echo $rtresp | jq .RouteTables[].RouteTableId | tr -d '"'`)
nc=${#c9rt[@]}
for t in ${c9rt[@]}; do
echo $t
aws ec2 create-route --route-table-id $t --destination-cidr-block $ekscidr --vpc-peering-connection-id $pid
done
