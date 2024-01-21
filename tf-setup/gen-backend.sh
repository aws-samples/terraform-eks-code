#!/bin/bash
echo "Setup Terraform cache"
if [ ! -f $HOME/.terraform.d/plugin-cache ]; then
  mkdir -p $HOME/.terraform.d/plugin-cache
  cp dot-terraform.rc $HOME/.terraformrc
fi

d=`pwd`
sleep 5
reg=`terraform output -json region | jq -r .[]`
#reg=$(echo "var.region" | terraform console 2> /dev/null | jq -r .)
if [[ -z ${reg} ]] ; then
    echo "no terraform output variables - exiting ....."
    echo "run terraform init/plan/apply in the the init directory first"
else
    echo "region=$reg"
fi
    s3b=`terraform output -json s3_bucket | jq -r .[]`
#
## using terragrunt for the DRY code might be a better approach than the below -
#
s3b=$(echo "aws_s3_bucket.terraform_state.id" | terraform console 2> /dev/null | jq -r .)

echo $s3b > tmp-buck.txt
mkdir -p generated

#default=["net","iam","c9net","cluster","nodeg","cicd","eks-cidr"]
SECTIONS=('tf-setup' 'net' 'c9net' 'cicd' 'cluster' 'addons' 'observ' 'sampleapp' 'fargate')
 
for section in "${SECTIONS[@]}"
do

    #tabn=`terraform output dynamodb_table_name_$section | tr -d '"'`
    tabn=$(printf "terraform_locks_%s" $section) 
    s3b=`terraform output -json s3_bucket | jq -r .[]`
    echo $s3b $tabn

    cd $d

    of=`echo "generated/backend-${section}.tf"`
    #vf=`echo "generated/vars-${section}.tf"`

    # write out the backend config 
    printf "" > $of
    printf "terraform {\n" >> $of
    printf "required_version = \"> 1.5.4\"\n" >> $of
    printf "required_providers {\n" >> $of
    printf "  aws = {\n" >> $of
    printf "   source = \"hashicorp/aws\"\n" >> $of
    printf "#  Lock version to avoid unexpected problems\n" >> $of
    printf "   version = \"5.30.0\"\n" >> $of
    printf "  }\n" >> $of
    printf "  kubernetes = {\n" >> $of
    printf "   source = \"hashicorp/kubernetes\"\n" >> $of
    printf "   version = \"2.24.0\"\n" >> $of
    printf "  }\n" >> $of
    printf "  kubectl = {\n" >> $of
    printf "    source  = \"gavinbunney/kubectl\"\n" >> $of
    printf "    version = \">= 1.14\"\n" >> $of
    printf "  }\n" >> $of
    printf " }\n" >> $of
    printf "backend \"s3\" {\n" >> $of
    printf "bucket = \"%s\"\n"  $s3b >> $of
    printf "key = \"terraform/%s.tfstate\"\n"  $tabn >> $of
    printf "region = \"%s\"\n"  $reg >> $of
    printf "dynamodb_table = \"%s\"\n"  $tabn >> $of
    printf "encrypt = \"true\"\n"   >> $of
    printf "}\n" >> $of
    printf "}\n" >> $of
    ##
    printf "provider \"aws\" {\n" >> $of
    printf "region = var.region\n"  >> $of
    printf "shared_credentials_files = [\"~/.aws/credentials\"]\n" >> $of
    #printf "profile = var.profile\n" >> $of
    printf "}\n" >> $of

done
# just for cicd k8s
section="sampleapp"
tabn=$(printf "terraform_locks_sampleapp" $section) 
s3b=`terraform output -json s3_bucket | jq -r .[]`
echo $s3b $tabn
cd $d
of=`echo "generated/backend-k8scicd.tf"`
    # write out the backend config 
    printf "" > $of
    printf "terraform {\n" >> $of
    printf "required_version = \"> 1.4.4\"\n" >> $of
    printf "required_providers {\n" >> $of
    printf "  kubernetes = {\n" >> $of
    printf "   source = \"hashicorp/kubernetes\"\n" >> $of
    printf "   version = \"2.17.0\"\n" >> $of
    printf "  }\n" >> $of
    printf " }\n" >> $of
    printf "backend \"s3\" {\n" >> $of
    printf "bucket = \"%s\"\n"  $s3b >> $of
    printf "key = \"terraform/%s.tfstate\"\n"  $tabn >> $of
    printf "region = \"%s\"\n"  $reg >> $of
    printf "dynamodb_table = \"%s\"\n"  $tabn >> $of
    printf "encrypt = \"true\"\n"   >> $of
    printf "}\n" >> $of
    printf "}\n" >> $of
    ##

cd $d
terraform fmt --recursive

exit 0
