#!/bin/bash
echo "Setup Terraform cache"
if [ ! -d "$HOME/.terraform.d/plugin-cache" ]; then
  mkdir -p "$HOME/.terraform.d/plugin-cache"
  cp dot-terraform.rc "$HOME/.terraformrc"
fi

d=$(pwd)
sleep 5
# TF_STATE_REGION / TF_STATE_BUCKET override the tf-setup outputs (e.g. for offline validation)
# (-json is used because -raw prints its "No outputs found" warning on stdout)
tfout=$(terraform output -json 2>/dev/null)
reg=${TF_STATE_REGION:-$(echo "$tfout" | jq -r '.region.value // empty' 2>/dev/null)}
s3b=${TF_STATE_BUCKET:-$(echo "$tfout" | jq -r '.s3_bucket.value // empty' 2>/dev/null)}
if [[ -z ${reg} || -z ${s3b} ]] ; then
    echo "no terraform output variables - exiting ....."
    echo "run terraform init/plan/apply in the the init directory first"
    exit 1
fi
echo "region=$reg"
#
## using terragrunt for the DRY code might be a better approach than the below -
#
echo "$s3b" > tmp-buck.txt
mkdir -p generated

SECTIONS=('tf-setup' 'net' 'cluster' 'nodepool' 'addons' 'observ' 'sampleapp' 'istio')
for section in "${SECTIONS[@]}"
do

    echo "$s3b" "$section"
    cd "$d" || exit 1

    of="generated/backend-${section}.tf"
    # All stages use helm provider 3 (observ moved to observability-accelerator v3)
    helm_ver="~> 3.3.0"
    #vf=`echo "generated/vars-${section}.tf"`

    # write out the backend config 
    printf "" > "$of"
    printf "terraform {\n" >> "$of"
    printf "required_version = \"> 1.12.0\"\n" >> "$of"
    printf "required_providers {\n" >> "$of"
    printf "  aws = {\n" >> "$of"
    printf "   source = \"hashicorp/aws\"\n" >> "$of"
    printf "#  Lock version to avoid unexpected problems\n" >> "$of"
    printf "   version = \"6.73.0\"\n" >> "$of"
    printf "  }\n" >> "$of"
    printf "  kubernetes = {\n" >> "$of"
    printf "   source = \"hashicorp/kubernetes\"\n" >> "$of"
    printf "   version = \"3.5.0\"\n" >> "$of"
    printf "  }\n" >> "$of"
    printf "  helm = {\n" >> "$of"
    printf "    source  = \"hashicorp/helm\"\n" >> "$of"
    printf "    version = \"%s\"\n" "$helm_ver" >> "$of"
    printf "  }\n" >> "$of"
    printf "  grafana = {\n" >> "$of"
    printf "    source  = \"grafana/grafana\"\n" >> "$of"
    printf "    version = \"~> 4.55.0\"\n" >> "$of"
    printf "  }\n" >> "$of"
    printf "  null = {\n" >> "$of"
    printf "    source  = \"hashicorp/null\"\n" >> "$of"
    printf "    version = \"~> 3.3.2\"\n" >> "$of"
    printf "  }\n" >> "$of"
    printf "  kubectl = {\n" >> "$of"
    printf "    source  = \"alekc/kubectl\"\n" >> "$of"
    printf "    version = \"~> 3.0.1\"\n" >> "$of"
    printf "  }\n" >> "$of"
    printf " }\n" >> "$of"
    printf "backend \"s3\" {\n" >> "$of"
    printf "bucket = \"%s\"\n"  "$s3b" >> "$of"
    printf "key = \"terraform/%s.tfstate\"\n"  "$section" >> "$of"
    printf "region = \"%s\"\n"  "$reg" >> "$of"
    printf "use_lockfile = true\n" >> "$of"
    printf "encrypt = true\n"   >> "$of"
    printf "}\n" >> "$of"
    printf "}\n" >> "$of"
    ##
    printf "provider \"aws\" {\n" >> "$of"
    printf "region = var.region\n"  >> "$of"
    printf "shared_credentials_files = [\"~/.aws/credentials\"]\n" >> "$of"
    #printf "profile = var.profile\n" >> "$of"
    printf "}\n" >> "$of"

done

cd "$d" || exit 1
terraform fmt --recursive

exit 0
