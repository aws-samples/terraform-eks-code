cd ~/environment
delete-environment
time eksctl delete cluster --name eks-workshop     # ~8min
#
# Why delete these ? - EFS so can zap VPC (has eni)
#
fsid=$(aws efs describe-file-systems --query FileSystems[].FileSystemId --output text)
for mtid in $(aws efs describe-mount-targets --file-system-id $fsid --query MountTargets[].MountTargetId --output text);do
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
aws rds delete-db-instance --db-instance-identifier $dbi --skip-final-snapshot
#
echo "delete VPC eksctl-eks-workshop-cluster"
vpcid=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksctl-eks-workshop-cluster/VPC --query Vpcs[].VpcId --output text)
echo $vpcid
echo "await RDS deletion then"
echo "aws ec2 delete-vpc --vpc-id $vpcid"
#
