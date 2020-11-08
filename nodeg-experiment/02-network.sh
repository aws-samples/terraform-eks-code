echo "vpce, peering, pering SG's"
CLOUD9_NAME="eks-c9"
# VPC endpoints mycluster1
resp=`aws eks describe-cluster --name mycluster1`
vpcid=`echo $resp | jq .cluster.resourcesVpcConfig.vpcId | tr -d '"'`
sgid=`echo $resp | jq .cluster.resourcesVpcConfig.securityGroupIds[0] | tr -d '"'`
csgid=`echo $resp | jq .cluster.resourcesVpcConfig.clusterSecurityGroupId | tr -d '"'`
ekscidr=`aws ec2 describe-vpcs --vpc-ids $vpcid | jq .Vpcs[0].CidrBlock | tr -d '"'`

resp=`aws ec2 describe-instances --filter Name=tag:Name,Values=*${CLOUD9_NAME}*`
c9vpcid=`echo $resp | jq .Reservations[0].Instances[0].VpcId | tr -d '"'`
c9sg=`echo $resp | jq .Reservations[0].Instances[0].NetworkInterfaces[0].Groups[0].GroupId | tr -d '"'`
c9cidr=`aws ec2 describe-vpcs --vpc-ids $c9vpcid | jq .Vpcs[0].CidrBlock | tr -d '"'`

echo "peering"
aws ec2 create-vpc-peering-connection --vpc-id $vpcid --peer-vpc-id $c9vpcid
sleep 10
pid=`aws ec2 describe-vpc-peering-connections | jq .VpcPeeringConnections[0].VpcPeeringConnectionId | tr -d '"'` 
echo $pid
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $pid

echo $c9vpcid $c9sg $c9cidr

eksrt=()
echo "eks rtb"
rtresp=`aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpcid Name=association.main,Values=false`
eksrt+=(`echo $rtresp | jq .RouteTables[].RouteTableId | tr -d '"'`)
nc=${#eksrt[@]}
for t in ${eksrt[@]}; do
echo $t
aws ec2 create-route --route-table-id $t --destination-cidr-block $c9cidr --vpc-peering-connection-id $pid
done


echo "c9 rtb"
rtresp=`aws ec2 describe-route-tables --filters Name=vpc-id,Values=$c9vpcid`
c9rt+=(`echo $rtresp | jq .RouteTables[].RouteTableId | tr -d '"'`)
nc=${#c9rt[@]}
for t in ${c9rt[@]}; do
echo $t
aws ec2 create-route --route-table-id $t --destination-cidr-block $ekscidr --vpc-peering-connection-id $pid
done




echo $vpcid
echo $sgid
echo $ekscidr





# need 4 route tables
#aws ec2 describe-subnets --subnet-ids $sub

# from each subnet in eks

#aws ec2 create-route --route-table-id $rtb --destination-cidr-block $c9cidr --vpc-peering-connection-id $pid


echo "vpce's"
echo "ec2messages"
aws ec2 create-vpc-endpoint --vpc-endpoint-type Interface --vpc-id $vpcid --service-name com.amazonaws.eu-west-1.ec2messages --security-group-ids $sgid
echo "ssmmessages"
aws ec2 create-vpc-endpoint --vpc-endpoint-type Interface --vpc-id $vpcid --service-name com.amazonaws.eu-west-1.ssmmessages --security-group-ids $sgid
echo "ssm"
aws ec2 create-vpc-endpoint --vpc-endpoint-type Interface --vpc-id $vpcid --service-name com.amazonaws.eu-west-1.ssm --security-group-ids $sgid


aws ec2 authorize-security-group-ingress --group-id $sgid --source-group $c9sg --protocol -1
aws ec2 authorize-security-group-ingress --group-id $csgid --source-group $c9sg --protocol -1
aws ec2 authorize-security-group-ingress --group-id $c9sg --source-group $sgid --protocol -1

# SG's