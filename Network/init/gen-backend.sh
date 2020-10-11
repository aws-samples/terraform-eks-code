
d=`pwd`
cd init
reg=`terraform output region`
if [[ -z ${reg} ]] ; then
echo "no terraform output variables - exiting ....."
else
echo "region=$reg"
rm -f backend.tf
fi


tabn=`terraform output dynamodb_table_name`
s3b=`terraform output s3_bucket`
echo $s3b $tabn


cd $d
printf "" > backend.tf
printf "terraform {\n" >> backend.tf
printf "required_version = \">= 0.12, < 0.13\"\n" >> backend.tf
printf "backend \"s3\" {\n" >> backend.tf
printf "bucket = \"%s\"\n"  $s3b >> backend.tf
printf "key = \"terraform/%s.tfstate\"\n"  $tabn >> backend.tf
printf "region = \"%s\"\n"  $reg >> backend.tf
printf "dynamodb_table = \"%s\"\n"  $tabn >> backend.tf
printf "encrypt = \"true\"\n"   >> backend.tf
printf "}\n" >> backend.tf
printf "}\n" >> backend.tf
printf "\n" >> backend.tf

printf "provider \"aws\" {\n" >> backend.tf
printf "region                  = var.region\n"  >> backend.tf
printf "shared_credentials_file = \"~/.aws/credentials\"\n" >> backend.tf
printf "profile                 = var.profile\n" >> backend.tf
printf "# Allow any 3.1x version of the AWS provider\n" >> backend.tf
printf "version = \"~> 3.10\"\n" >> backend.tf
printf "}\n" >> backend.tf

cp init/vars.tf .





