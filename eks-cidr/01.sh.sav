
nc=`aws eks list-clusters | jq '.clusters | length'`
if [ $nc == 1 ] ; then
export CLUSTER=`aws eks list-clusters | jq '.clusters[0]' | tr -d '"'`
echo "EKS Cluster = $CLUSTER"
else
echo "Please set the environment variable CLUSTER"
exit
fi
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksctl-eksworkshop* | jq -r '.Vpcs[].VpcId')
echo $VPC_ID
aws ec2 associate-vpc-cidr-block --vpc-id $VPC_ID --cidr-block 100.64.0.0/16
aws ec2 describe-instances --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=eksworkshop*" --query 'Reservations[*].Instances[*].[PrivateDnsName,Tags[?Key==`eks:nodegroup-name`].Value|[0],Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress]' --output table   
reg=`aws configure get region`
export AZ1=${reg}a
export AZ2=${reg}b
export AZ3=${reg}c
CGNAT_SNET1=$(aws ec2 create-subnet --cidr-block 100.64.0.0/19 --vpc-id $VPC_ID --availability-zone $AZ1 | jq -r .Subnet.SubnetId)
CGNAT_SNET2=$(aws ec2 create-subnet --cidr-block 100.64.32.0/19 --vpc-id $VPC_ID --availability-zone $AZ2 | jq -r .Subnet.SubnetId)
CGNAT_SNET3=$(aws ec2 create-subnet --cidr-block 100.64.64.0/19 --vpc-id $VPC_ID --availability-zone $AZ3 | jq -r .Subnet.SubnetId)
aws ec2 describe-subnets --filters Name=cidr-block,Values=192.168.0.0/19 --output text
aws ec2 create-tags --resources $CGNAT_SNET1 --tags Key=eksctl.cluster.k8s.io/v1alpha1/cluster-name,Value=eksworkshop-eksctl
aws ec2 create-tags --resources $CGNAT_SNET1 --tags Key=kubernetes.io/cluster/eksworkshop-eksctl,Value=shared
aws ec2 create-tags --resources $CGNAT_SNET1 --tags Key=kubernetes.io/role/elb,Value=1
aws ec2 create-tags --resources $CGNAT_SNET2 --tags Key=eksctl.cluster.k8s.io/v1alpha1/cluster-name,Value=eksworkshop-eksctl
aws ec2 create-tags --resources $CGNAT_SNET2 --tags Key=kubernetes.io/cluster/eksworkshop-eksctl,Value=shared
aws ec2 create-tags --resources $CGNAT_SNET2 --tags Key=kubernetes.io/role/elb,Value=1
aws ec2 create-tags --resources $CGNAT_SNET3 --tags Key=eksctl.cluster.k8s.io/v1alpha1/cluster-name,Value=eksworkshop-eksctl
aws ec2 create-tags --resources $CGNAT_SNET3 --tags Key=kubernetes.io/cluster/eksworkshop-eksctl,Value=shared
aws ec2 create-tags --resources $CGNAT_SNET3 --tags Key=kubernetes.io/role/elb,Value=1

SNET1=$(aws ec2 describe-subnets --filters Name=cidr-block,Values=192.168.0.0/19 | jq -r '.Subnets[].SubnetId')
RTASSOC_ID=$(aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$SNET1 | jq -r '.RouteTables[].RouteTableId')
aws ec2 associate-route-table --route-table-id $RTASSOC_ID --subnet-id $CGNAT_SNET1
aws ec2 associate-route-table --route-table-id $RTASSOC_ID --subnet-id $CGNAT_SNET2
aws ec2 associate-route-table --route-table-id $RTASSOC_ID --subnet-id $CGNAT_SNET3








