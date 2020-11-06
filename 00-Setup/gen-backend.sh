
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
cp -v $of ../$section

cp -v vars.tf ../$section

done


cd $d
of=`echo "generated/remote-state.tf"`
printf "" > $of

SECTIONS=('net' 'iam' 'c9net' 'cluster') 
for section in "${SECTIONS[@]}"
do

tabn=`terraform output dynamodb_table_name_$section`
s3b=`terraform output s3_bucket`
echo $s3b $tabn

printf "data terraform_remote_state \"%s\" {\n" $section>> $of
printf "backend = \"s3\"\n" >> $of
printf "config = {\n" >> $of
printf "bucket = \"%s\"\n"  $s3b >> $of
printf "region = \"%s\"\n"  $reg >> $of
printf "key = \"terraform/%s.tfstate\"\n"  $tabn >> $of
printf "}\n" >> $of
printf "}\n" >> $of

done

for section in "${SECTIONS[@]}"
do
cp -v $of ../$section
done


