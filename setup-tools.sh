echo "Install OS tools"
sudo yum -y -q -e 0 install  jq moreutils nmap > /dev/null
echo "Update OS tools"
sudo yum update -y > /dev/null
echo "Update pip"
sudo pip install --upgrade pip > /dev/null
echo "Uninstall AWS CLI v1"
sudo /usr/local/bin/pip uninstall awscli -y > /dev/null

echo "Install AWS CLI v2"
curl --silent "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" > /dev/null
unzip -qq awscliv2.zip
sudo ./aws/install > /dev/null
rm -f awscliv2.zip
rm -rf aws

# setup for AWS cli
aws sts get-caller-identity --query Arn | grep eksworkshop-admin > /dev/null
if [ $? -eq 0 ]; then
  rm -vf ${HOME}/.aws/credentials
  export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
  export TF_VAR_region=$(echo $AWS_REGION)
  export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
  test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo AWS_REGION is not set !!
  echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
  echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
  export TF_VAR_region=${AWS_REGION}
  echo "export TF_VAR_region=${AWS_REGION}" | tee -a ~/.bash_profile
  aws configure set default.region ${AWS_REGION}
  aws configure get region
fi

echo "Setup Terraform cache"
if [ ! -f $HOME/.terraform.d/plugin-cache ];then
  mkdir -p $HOME/.terraform.d/plugin-cache
  cp tfinit/dot-terraform.rc $HOME/.terraformrc
fi
echo "Setup kubectl"
if [ ! `which kubectl 2> /dev/null` ]; then
  echo "Install kubectl"
  curl --silent -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl  > /dev/null
  chmod +x ./kubectl
  sudo mv ./kubectl  /usr/local/bin/kubectl > /dev/null
  kubectl completion bash >>  ~/.bash_completion
fi

if [ ! `which eksctl 2> /dev/null` ]; then
echo "install eksctl"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp   > /dev/null
sudo mv -v /tmp/eksctl /usr/local/bin > /dev/null
echo "eksctl completion"
eksctl completion bash >> ~/.bash_completion
fi

if [ ! `which helm 2> /dev/null` ]; then
  echo "helm"
  wget -q https://get.helm.sh/helm-v3.5.4-linux-amd64.tar.gz > /dev/null
  tar -zxf helm-v3.5.4-linux-amd64.tar.gz
  sudo mv linux-amd64/helm /usr/local/bin/helm > /dev/null
  rm -rf helm-v3.5.4-linux-amd64.tar.gz linux-amd64
fi
echo "add helm repos"
helm repo add eks https://aws.github.io/eks-charts

if [ ! `which kubectx 2> /dev/null` ]; then
  echo "kubectx"
  sudo git clone -q https://github.com/ahmetb/kubectx /opt/kubectx > /dev/null
  sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
  sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
fi



echo "ssh key"
if [ ! -f ~/.ssh/id_rsa ]; then
  mkdir -p ~/.ssh
  ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
  chmod 600 ~/.ssh/id*
fi
aws ec2 delete-key-pair --key-name "eksworkshop" > /dev/null
aws ec2 import-key-pair --key-name "eksworkshop" --public-key-material fileb://~/.ssh/id_rsa.pub > /dev/null
echo "KMS key"
aws kms create-alias --alias-name alias/eksworkshop --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)
export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)
if [ ! -z $MASTER_ARN ];then
echo "export MASTER_ARN=${MASTER_ARN}" | tee -a ~/.bash_profile
fi

echo "git-remote-codecommit"
pip install git-remote-codecommit > /dev/null

echo "Verify ...."
for command in jq aws wget kubectl terraform eksctl helm kubectx
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done


this=`pwd`
#echo "sample apps"
cd ~/environment
#git clone https://github.com/brentley/ecsdemo-frontend.git
#git clone https://github.com/brentley/ecsdemo-nodejs.git
#git clone https://github.com/brentley/ecsdemo-crystal.git
#git clone https://github.com/aws-samples/aws2tf.git

echo "Enable bash_completion"
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
echo "alias tfb='terraform init && terraform plan -out tfplan && terraform apply tfplan && terraform init -force-copy'" >> ~/.bash_profile
echo "alias aws='/usr/local/bin/aws'" >> ~/.bash_profile
source ~/.bash_profile

#aws --version
#eksctl version
#Install  version --client
#helm version

test -n "$AWS_REGION" && echo "PASSED: AWS_REGION is $AWS_REGION" || echo AWS_REGION is not set !!
test -n "$ACCOUNT_ID" && echo "PASSED: ACCOUNT_ID is $ACCOUNT_ID" || echo ACCOUNT_ID is not set !!
echo "setup tools run" >> ~/setup-tools.log

cd ~/environment/tfekscode/Launch/lb2
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json -s

cd $this
