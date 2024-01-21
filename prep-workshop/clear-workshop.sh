cd ~/environment
time eksctl delete cluster  --name eks-workshop     # ~8min
fsid=$(aws efs describe-file-systems --query FileSystems[].FileSystemId --output text)
for mtid in $(aws efs describe-mount-targets --file-system-id $fsid --query MountTargets[].MountTargetId --output text);do
echo $mtid
aws efs delete-mount-target --mount-target-id $mtid
done
echo "sleep 30s to allow mount targets to delete"
sleep 30
aws efs delete-file-system --file-system-id $fsid
dbi=$(aws rds describe-db-instances --query DBInstances[].DBInstanceIdentifier --output text)
aws rds delete-db-instance --db-instance-identifier $dbi --skip-final-snapshot