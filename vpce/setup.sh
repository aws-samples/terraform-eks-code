
export CLUSTER="manamieks"
test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || export AWS_REGION="eu-west-2"
test -n "$AWS_PROFILE" && echo AWS_PROFILE is "$AWS_PROFILE" || export AWS_PROFILE="default"
export AWS="aws --profile $AWS_PROFILE --region $AWS_REGION"
printf "provider \"aws\" {\n" > aws.tf
printf " region = \"%s\" \n" $AWS_REGION >> aws.tf
printf " shared_credentials_file = \"~/.aws/credentials\" \n"  >> aws.tf
printf " version = \"= 3.10.0\" \n"  >> aws.tf
printf " profile = \"%s\" \n" $AWS_PROFILE >> aws.tf
printf "}\n" >> aws.tf