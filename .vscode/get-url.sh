iid=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=VSCodeServer" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].[InstanceId]' --output text)
echo $iid
distro=$(aws cloudfront list-distributions --query 'DistributionList.Items[].Id[]' | jq -r '.[]')
echo "check origin internal ip"
idn=$(aws cloudfront get-distribution --id $distro --query "Distribution.DistributionConfig.Origins.Items[].DomainName"| jq -r '.[]')
echo $idn
edn=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=VSCodeServer" --query "Reservations[*].Instances[*].PrivateDnsName" --output text)
echo $edn
url=$(aws cloudfront get-distribution --id $distro --query "Distribution.DomainName" --output text)
echo "$url/?folder=/home/ec2-user/environment"
printf "password: "
aws cloudformation describe-stacks \
  --stack-name vscode \
  --query "Stacks[0].Outputs[?OutputKey=='Password'].OutputValue" \
  --output text
echo " "
aws secretsmanager get-secret-value --secret-id VSCodeServer --query SecretString --output text