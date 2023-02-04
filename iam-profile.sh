#! /bin/bash
aws iam create-role --role-name eksworkshop-admin2 --assume-role-policy-document file://trust.json
aws iam create-policy --policy-name tfeks2  --policy-document file://policy.json
aws iam attach-role-policy --role-name eksworkshop-admin2 --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

instance_id=$(curl -sS http://169.254.169.254/latest/meta-data/instance-id)
profile_name="eksworkshop-admin"

if aws ec2 associate-iam-instance-profile --iam-instance-profile "Name=$profile_name" --instance-id $instance_id; then
  echo "Profile associated successfully."
else
  echo "ERROR: Encountered error associating instance profile eksworkshop-admin with Cloud9 environment"
fi