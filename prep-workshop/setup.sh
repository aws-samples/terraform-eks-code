echo "Setup Terraform cache"
if [ ! -f $HOME/.terraform.d/plugin-cache ]; then
  mkdir -p $HOME/.terraform.d/plugin-cache
  cp dot-terraform.rc $HOME/.terraformrc
fi
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export TF_VAR_region=${AWS_REGION}
test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo "AWS_REGION is not set !!"
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
echo "export TF_VAR_region=${AWS_REGION}" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get region

