#! /bin/bash
aws iam create-role --role-name eksworkshop-admin --assume-role-policy-document file://trust.json

instance_id=$(curl -sS http://169.254.169.254/latest/meta-data/instance-id)
profile_name="eksworkshop-admin"

if aws ec2 associate-iam-instance-profile --iam-instance-profile "Name=$profile_name" --instance-id $instance_id; then
  echo "Profile associated successfully."
else
  echo "ERROR: Encountered error associating instance profile eksworkshop-admin with Cloud9 environment"
fi