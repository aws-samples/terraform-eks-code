#! /bin/bash
profile_name="eksworkshop-admin"
instance_id=$(curl -sS http://169.254.169.254/latest/meta-data/instance-id)
ipa=$(aws ec2 describe-instances --instance-ids $instance_id --query Reservations[].Instances[].IamInstanceProfile | jq -r .[].Arn)
iip=$(aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$instance_id" --query IamInstanceProfileAssociations[].AssociationId | jq -r .[])
if aws ec2 replace-iam-instance-profile-association --iam-instance-profile "Name=$profile_name" --association-id $iip; then
  echo "Profile associated successfully."
else
  echo "ERROR: Encountered error associating instance profile eksworkshop-admin with Cloud9 environment"
fi