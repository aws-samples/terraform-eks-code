
d=`pwd`
sleep 5
reg=`terraform output region`
if [[ -z ${reg} ]] ; then
echo "no terraform output variables - exiting ....."
echo "run terraform init/plan/apply in the the init directory first"
else
echo "region=$reg"
rm -f $of $of
fi


SECTIONS=('net' 'iam' 'c9net' 'cluster' 'nodeg')
 
for section in "${SECTIONS[@]}"
do

tabn=`terraform output dynamodb_table_name_$section`
s3b=`terraform output s3_bucket`
echo $s3b $tabn


cd $d
of=`echo "generated/backend-${section}.tf"`
vf=`echo "generated/vars-${section}.tf"`
printf "" > $of
printf "terraform {\n" >> $of
printf "required_version = \">= 0.12, < 0.13\"\n" >> $of
printf "backend \"s3\" {\n" >> $of
printf "bucket = \"%s\"\n"  $s3b >> $of
printf "key = \"terraform/%s.tfstate\"\n"  $tabn >> $of
printf "region = \"%s\"\n"  $reg >> $of
printf "dynamodb_table = \"%s\"\n"  $tabn >> $of
printf "encrypt = \"true\"\n"   >> $of
printf "}\n" >> $of
printf "}\n" >> $of
printf "\n" >> $of
printf "provider \"aws\" {\n" >> $of
printf "region = var.region\n"  >> $of
printf "shared_credentials_file = \"~/.aws/credentials\"\n" >> $of
printf "profile = var.profile\n" >> $of
printf "# Allow any 3.1x version of the AWS provider\n" >> $of
printf "version = \"~> 3.10\"\n" >> $of
printf "}\n" >> $of

printf "" > $vf
printf "variable \"bucket_name\" {\n" >> $vf
printf "  description = \"The name of the S3 bucket. Must be globally unique.\"\n" >> $vf
printf "  type        = string\n" >> $vf
printf "  default     = \"%s\"\n" $s3b >> $vf
printf "}\n" >> $vf


cp -v $of ../$section
cp -v $vf ../$section
cp -v vars-dynamodb.tf ../$section

done


cd $d


SECTIONS=('net' 'iam' 'c9net' 'cluster') 
for section in "${SECTIONS[@]}"
do

tabn=`terraform output dynamodb_table_name_$section`
s3b=`terraform output s3_bucket`
echo $s3b $tabn
of=`echo "generated/remote-${section}.tf"`
printf "" > $of

printf "data terraform_remote_state \"%s\" {\n" $section>> $of
printf "backend = \"s3\"\n" >> $of
printf "config = {\n" >> $of
printf "bucket = \"%s\"\n"  $s3b >> $of
printf "region = \"%s\"\n"  $reg >> $of
printf "key = \"terraform/%s.tfstate\"\n"  $tabn >> $of
printf "}\n" >> $of
printf "}\n" >> $of

done

cp -v generated/remote-net.tf ../c9net 
cp -v generated/remote-net.tf ../cluster
cp -v generated/remote-net.tf ../nodeg

cp -v generated/remote-iam.tf ../cluster 
cp -v generated/remote-iam.tf ../nodeg

cp -v generated/remote-cluster.tf ../nodeg

# upload tools into remote bucket
wget https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip
wget https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
curl -s -qL -o jq https://stedolan.github.io/jq/download/linux64/jq
aws s3 cp terraform_0.12.29_linux_amd64.zip s3://$s3b/tools/terraform_0.12.29_linux_amd64.zip
aws s3 cp kubectl s3://$s3b/tools/kubectl
aws s3 cp jq s3://$s3b/tools/jq
rm -rf terraform_0.12.29_linux_amd64.zip kubectl
