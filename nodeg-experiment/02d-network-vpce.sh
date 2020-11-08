nc=`aws eks list-clusters | jq '.clusters | length'`
if [ $nc == 1 ] ; then
export CLUSTER=`aws eks list-clusters | jq '.clusters[0]' | tr -d '"'`
echo "EKS Cluster = $CLUSTER"
else
    if  [ -z "$CLUSTER" ] ;then
        echo "Please set the environment variable CLUSTER"
        exit
    fi
fi
resp=`aws eks describe-cluster --name $CLUSTER`
vpcid=`echo $resp | jq .cluster.resourcesVpcConfig.vpcId | tr -d '"'`
sgid=`echo $resp | jq .cluster.resourcesVpcConfig.securityGroupIds[0] | tr -d '"'`

subs=()
subs+=`aws ec2 describe-subnets  --filters Name=vpc-id,Values=$vpcid Name=cidr-block,Values=192.168.*19 Name=tag-key,Values=kubernetes.io/role/internal-elb Name=tag-value,Values=1 Name=tag-key,Values=kubernetes.io/cluster/mycluster1 | jq -r '.Subnets[].SubnetId'`
echo $subs
sgshared=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=$vpcid Name=group-name,Values=*ClusterShared* Name=tag-value,Values=$CLUSTER | jq -r .SecurityGroups[].GroupId)
echo $sgshared
if [ -z $sgshared ]; then
echo "shared node security group not found exiting .."
exit
else
echo "shared node security group = $sgshared"
fi

echo "vpce's"
echo "ec2messages"
aws ec2 create-vpc-endpoint --vpc-endpoint-type Interface --vpc-id $vpcid --service-name com.amazonaws.eu-west-1.ec2messages --security-group-ids $sgshared --subnet-ids $subs
echo "ssmmessages"
aws ec2 create-vpc-endpoint --vpc-endpoint-type Interface --vpc-id $vpcid --service-name com.amazonaws.eu-west-1.ssmmessages --security-group-ids $sgshared --subnet-ids $subs
echo "ssm"
aws ec2 create-vpc-endpoint --vpc-endpoint-type Interface --vpc-id $vpcid --service-name com.amazonaws.eu-west-1.ssm --security-group-ids $sgshared --subnet-ids $subs
