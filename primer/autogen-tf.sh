
cd ~/environment/aws2tf
tgwids=`aws ec2 describe-transit-gateways --query "TransitGateways[].TransitGatewayId" | jq .[]`
for j in $tgwids; do
tgid=`echo $j | tr -d '"'`
./aws2tf.sh -t tgw -i $tgid
done

vpcids=`aws ec2 describe-vpcs --filters "Name=isDefault,Values=false" --query "Vpcs[].VpcId" | jq .[]`
for i in $vpcids; do
vpcid=`echo $i | tr -d '"'`
./aws2tf.sh -t vpc -i $vpcid -c yes
done

./aws2tf.sh -t inst -c yes

