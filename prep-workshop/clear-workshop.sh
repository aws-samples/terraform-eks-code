cd ~/environment
echo "This will take ~ 20 minutes"
delete-environment
time eksctl delete cluster --name eks-workshop # ~8min
#
# Why delete these ? - EFS so can zap VPC (has eni)
#
fsid=$(aws efs describe-file-systems --query FileSystems[].FileSystemId --output text)
for mtid in $(aws efs describe-mount-targets --file-system-id $fsid --query MountTargets[].MountTargetId --output text); do
    echo $mtid
    aws efs delete-mount-target --mount-target-id $mtid
done
echo "sleep 30s to allow mount targets to delete"
sleep 30
aws efs delete-file-system --file-system-id $fsid
#
# Same for RDS
#
dbi=$(aws rds describe-db-instances --query DBInstances[].DBInstanceIdentifier --output text)
aws rds delete-db-instance --db-instance-identifier $dbi --skip-final-snapshot &> /dev/null
#
echo "await RDS deletion"
rdsst=$(aws rds describe-db-instances --db-instance-identifier eks-workshop-catalog --query 'DBInstances[].DBInstanceStatus' --output text)
while [[ $rdsst != "" ]]; do
    echo $rdsst
    sleep 10
    rdsst=$(aws rds describe-db-instances --db-instance-identifier eks-workshop-catalog --query 'DBInstances[].DBInstanceStatus' --output text)
done
echo "delete VPC eksctl-eks-workshop-cluster"
vpcid=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksctl-eks-workshop-cluster/VPC --query Vpcs[].VpcId --output text)
echo $vpcid

sgs=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpcid --query SecurityGroups[].GroupId --output text)
for i in $sgs; do
    echo $i
    aws ec2 delete-security-group --group-id $i &> /dev/null
done
for i in $sgs; do
    echo $i
    aws ec2 delete-security-group --group-id $i &> /dev/null
done
echo "await RDS deletion"
rdsst=$(aws rds describe-db-instances --db-instance-identifier eks-workshop-catalog --query 'DBInstances[].DBInstanceStatus' --output text)
while [[ $rdsst != "" ]]; do
    echo $rdsst
    sleep 10
    rdsst=$(aws rds describe-db-instances --db-instance-identifier eks-workshop-catalog --query 'DBInstances[].DBInstanceStatus' --output text)
done
echo "aws ec2 delete-vpc --vpc-id $vpcid"
aws ec2 delete-vpc --vpc-id $vpcid
echo "done"
#
