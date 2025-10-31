url=$(aws cloudfront get-distribution --id EEZ8MHOD4HTNX --query "Distribution.DomainName" --output text)
echo "$url/?folder=/home/ec2-user/environment"