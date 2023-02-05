#! /bin/bash
rolen="eksworkshop-admin"
profile_name="eksworkshop-admin"
aws iam create-role --role-name $rolen --assume-role-policy-document file://trust.json
aws iam create-policy --policy-name tfeks  --policy-document file://policy.json
parn=$(aws iam list-policies --scope Local | jq -r '.Policies[] | select(.PolicyName=="tfeks").Arn')
aws iam attach-role-policy --role-name $rolen --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam attach-role-policy --role-name $rolen --policy-arn $parn
aws iam create-instance-profile --instance-profile-name $profile_name
aws iam add-role-to-instance-profile --instance-profile-name $profile_name --role-name $rolen
instance_id=$(curl -sS http://169.254.169.254/latest/meta-data/instance-id)
ipa=$(aws ec2 describe-instances --instance-ids $instance_id --query Reservations[].Instances[].IamInstanceProfile | jq -r .[].Arn)
iip=$(aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$instance_id" --query IamInstanceProfileAssociations[].AssociationId | jq -r .[])
if aws ec2 replace-iam-instance-profile-association --iam-instance-profile "Name=$profile_name" --association-id $iip; then
  echo "Profile associated successfully."
else
  echo "ERROR: Encountered error associating instance profile eksworkshop-admin with Cloud9 environment"
fi