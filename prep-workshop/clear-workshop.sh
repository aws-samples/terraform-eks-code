cd ~/environment
echo "This will take ~ 10 minutes"
date
fsid=$(aws efs describe-file-systems --query FileSystems[].FileSystemId --output text)
if [[ $fsid != "" ]]; then
    for mtid in $(aws efs describe-mount-targets --file-system-id $fsid --query MountTargets[].MountTargetId --output text); do
        echo $mtid
        aws efs delete-mount-target --mount-target-id $mtid
    done
    echo "sleep 30s to allow mount targets to delete"
    sleep 30
    aws efs delete-file-system --file-system-id $fsid
fi
#
# Same for RDS
#
echo "Delete RDS Instance..."
dbi=$(aws rds describe-db-instances --query DBInstances[].DBInstanceIdentifier --output text 2>/dev/null || true)
if [[ $dbi != "" ]]; then
    aws rds delete-db-instance --db-instance-identifier $dbi --skip-final-snapshot &>/dev/null
#
#delete-environment
# helm and ns delete ?
#
fi
echo "Delete the EKS cluster ...."
eksctl delete cluster --name eks-workshop 2>/dev/null # ~8min
#
# Why delete these ? - EFS so can zap VPC (has eni)
#
#if [[ $dbi != "" ]]; then
    echo "await RDS db instance deletion ..."
    rdsst=$(aws rds describe-db-instances --db-instance-identifier eks-workshop-catalog --query 'DBInstances[].DBInstanceStatus' --output text 2>/dev/null || true)
    while [[ $rdsst != "" ]]; do
        echo $rdsst
        sleep 10
        rdsst=$(aws rds describe-db-instances --db-instance-identifier eks-workshop-catalog --query 'DBInstances[].DBInstanceStatus' --output text)
    done
#fi

vpcid=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksctl-eks-workshop-cluster/VPC --query Vpcs[].VpcId --output text)
echo $vpcid
if [[ $vpcid != "" ]]; then
    echo "delete VPC eksctl-eks-workshop-cluster"

    sgs=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpcid --query SecurityGroups[].GroupId --output text)
    for i in $sgs; do
        echo $i
        aws ec2 delete-security-group --group-id $i &>/dev/null
    done
    for i in $sgs; do
        echo $i
        aws ec2 delete-security-group --group-id $i &>/dev/null
    done
    ## 2nd go at security groups
    vpcid=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksctl-eks-workshop-cluster/VPC --query Vpcs[].VpcId --output text)
    echo $vpcid

    sgs=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpcid --query SecurityGroups[].GroupId --output text)
    for i in $sgs; do
        echo $i
        aws ec2 delete-security-group --group-id $i &>/dev/null
        sleep 1
    done
    echo "sleep 30s for sync ..."
    sleep 30
    for i in $sgs; do
        echo $i
        aws ec2 delete-security-group --group-id $i &>/dev/null
        sleep 1
    done
    # delete subnets
    echo "sleep 30s for sync ..."
    echo "Delete the vpc ...."
    echo "aws ec2 delete-vpc --vpc-id $vpcid"
    aws ec2 delete-vpc --vpc-id $vpcid
    if [[ $? -ne 0 ]]; then
        echo ""
        echo "If VPC $vpcid still exists/failed to delete - wait 1 miniute then re-run ./clear-workshop.sh"
        echo ""
    else
        echo "Done"
    fi
fi
#
