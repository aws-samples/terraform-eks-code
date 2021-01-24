echo "Check my profile"
instid=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id`
echo $instid
ip=`aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$instid" | jq .IamInstanceProfileAssociations[0].IamInstanceProfile.Arn | cut -f2 -d'/' | tr -d '"'`
echo $ip
if [ "$ip" != "eksworkshop-admin" ] ; then
echo "Could not find Instance profile eksworkshop-admin! - DO NOT PROCEED exiting"
exit
else
echo "OK Found Instance profile eksworkshop-admin - proceed with the workshop"
fi
aws sts get-caller-identity --query Arn | grep eksworkshop-admin -q && echo "IAM role valid - eksworkshop-admin" || echo "IAM role not valid - DO NOT PROCEED"
iname=$(aws ec2 describe-tags --filters "Name=resource-type,Values=instance" "Name=resource-id,Values=$instid" | jq -r '.Tags[] | select(.Key=="Name").Value')
echo $iname| grep eks-terraform -q && echo "Cloud9 IDE name is valid - contains eks-terraform" || echo "Cloud9 IDE name invalid! - DO NOT PROCEED"
