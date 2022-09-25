#!/bin/bash
cp dot-terraform.rc $HOME/.terraformrc
d=`pwd`
#sleep 5
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

echo $s3b
echo $reg
mkdir -p generated

#default=["net","iam","c9net","cluster","nodeg","cicd","eks-cidr"]
SECTIONS=('net' 'iam' 'c9net' 'cicd' 'cluster' 'nodeg' 'eks-cidr' 'sampleapp')
 
for section in "${SECTIONS[@]}"
do

    #tabn=`terraform output dynamodb_table_name_$section | tr -d '"'`
    tabn=$(printf "terraform_lock_%s" $section) 
    echo $s3b $tabn

    cd $d

    of=`echo "generated/backend-${section}.tf"`
    #vf=`echo "generated/vars-${section}.tf"`

    # write out the backend config 
    printf "" > $of
    printf "terraform {\n" >> $of
    printf "required_version = \"~> 1.3.0\"\n" >> $of
    printf "required_providers {\n" >> $of
    printf "  aws = {\n" >> $of
    printf "   source = \"hashicorp/aws\"\n" >> $of
    printf "#  Lock version to avoid unexpected problems\n" >> $of
    printf "   version = \"4.31.0\"\n" >> $of
    printf "  }\n" >> $of
    printf "  kubernetes = {\n" >> $of
    printf "   source = \"hashicorp/kubernetes\"\n" >> $of
    printf "   version = \"2.13.1\"\n" >> $of
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
    printf "profile = var.profile\n" >> $of
    printf "}\n" >> $of

    # copy the files into place
    #cp -v $of ../$section
    # link these
    #cp  -v vars-dynamodb.tf ../$section
    #cp  -v vars-main.tf ../$section

done

# next generate the remote_state config files 


cd $d


# put in place remote state access where required
#cp  -v generated/remote-net.tf ../c9net 
#cp  -v generated/remote-net.tf ../cluster
#cp  -v generated/remote-net.tf ../nodeg
#cp  -v generated/remote-net.tf ../extra/nodeg2
#cp  -v generated/remote-net.tf ../eks-cidr
#cp  -v generated/remote-net.tf ../extra/eks-cidr2
#cp  -v generated/remote-net.tf ../extra/.fargate

#cp  -v generated/remote-nodeg.tf ../extra/.karpenter

#cp  -v generated/remote-iam.tf ../cluster 
#cp  -v generated/remote-iam.tf ../nodeg
#cp  -v generated/remote-iam.tf ../extra/nodeg2

#echo "Copy remote-cluster.tf"
#cp  -v generated/remote-cluster.tf ../nodeg
#cp  -v generated/remote-cluster.tf ../eks-cidr
#cp  -v generated/remote-cluster.tf ../extra/eks-cidr2
#cp  -v generated/remote-cluster.tf ../lb2
#cp  -v generated/remote-cluster.tf ../extra/nodeg2
#cp  -v generated/remote-cluster.tf ../extra/.fargate

# Prepare "local state" for the sample app and extra activities
#cp  aws.tf ../sampleapp
echo "Copy vars/aws.tf"

#link

cd ~/environment/tfekscode
terraform fmt --recursive > /dev/null
exit 0
