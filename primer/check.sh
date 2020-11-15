. ~/.bash_profile
if  [ -n "$AWS_REGION" ] ;then
echo "AWS_REGION is $AWS_REGION" 
else
echo "AWS_REGION is not set this must be done before proceeding"
exit
fi

kn=`aws ec2 describe-key-pairs --query "KeyPairs[?KeyName=='networkshop'].KeyName" | grep net | tr -d ' ' | tr -d '"'`
if [ $kn != "networkshop" ]; then
echo "Could not find eksworkshop key pair - create before proceeding"
exit
fi


aws sts get-caller-identity --query Arn | grep eksworkshop-admin -q && echo "IAM role valid eksworkshop-admin OK to proceed" || echo "IAM role NOT validi DO NOT PROCEED"
