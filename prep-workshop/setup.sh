echo "Setup Terraform cache"
if [ ! -f $HOME/.terraform.d/plugin-cache ]; then
  mkdir -p $HOME/.terraform.d/plugin-cache
  cp dot-terraform.rc $HOME/.terraformrc
fi
echo "Install flux cli"
curl -s https://fluxcd.io/install.sh | sudo bash
flux --version
#echo "Install kubectl v1.27.7"
#curl -LO https://dl.k8s.io/release/v1.27.7/bin/linux/amd64/kubectl
#curl --silent -LO https://dl.k8s.io/release/v1.24.14/bin/linux/amd64/kubectl >/dev/null
#chmod +x ./kubectl
#sudo mv ./kubectl /usr/local/bin/kubectl >/dev/null
#kubectl completion bash >>~/.bash_completion
#echo "Install eksctl"
#curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp >/dev/null
#sudo mv -v /tmp/eksctl /usr/local/bin >/dev/null
#eksctl completion bash >>~/.bash_completion
#curl -L -o kubectl-cert-manager.tar.gz https://github.com/jetstack/cert-manager/releases/latest/download/kubectl-cert_manager-linux-amd64.tar.gz
#tar xzf kubectl-cert-manager.tar.gz
#sudo mv kubectl-cert_manager /usr/local/bin
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export TF_VAR_region=${AWS_REGION}
test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo "AWS_REGION is not set !!"
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
echo "export TF_VAR_region=${AWS_REGION}" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get region

