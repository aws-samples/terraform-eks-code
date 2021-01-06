rm -vf ${HOME}/.aws/credentials
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo AWS_REGION is not set !!
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region

echo "kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

echo "update aws cli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -qq awscliv2.zip
sudo ./aws/install
rm -f awscliv2.zip
rm -rf aws
#sudo pip install --upgrade awscli && hash -r

echo "other tools"
sudo yum -y -q -e 0 install jq moreutils bash-completion nmap

#echo 'yq() {
#  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq yq "$@"
#}' | tee -a ~/.bash_profile && source ~/.bash_profile


echo "Terraform"
wget https://releases.hashicorp.com/terraform/0.14.3/terraform_0.14.3_linux_amd64.zip
unzip -qq terraform_0.14.3_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm -f terraform_0.14.3_linux_amd64.zip


echo "Enable kubectl bash_completion"
kubectl completion bash >>  ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

echo "ssh key"
mkdir -p ~/.ssh
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
chmod 600 ~/.ssh/id*
aws ec2 delete-key-pair --key-name "eksworkshop"
aws ec2 import-key-pair --key-name "eksworkshop" --public-key-material fileb://~/.ssh/id_rsa.pub
echo "KMS key"
aws kms create-alias --alias-name alias/eksworkshop --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)
export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)
echo "export MASTER_ARN=${MASTER_ARN}" | tee -a ~/.bash_profile

echo "install eksctl"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin
echo "eksctl completion"
eksctl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
echo "helm"
wget https://get.helm.sh/helm-v3.2.1-linux-amd64.tar.gz
tar -zxf helm-v3.2.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm-v3.2.1-linux-amd64.tar.gz linux-amd64
echo "add helm repos"
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo add eks https://aws.github.io/eks-charts


echo "kubectx"
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

echo "git-remote-codecommit"
pip install git-remote-codecommit

echo "verify"
for command in kubectl jq envsubst aws wget terraform eksctl helm kubectx
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done


this=`pwd`
echo "sample apps"
cd ~/environment
#git clone https://github.com/brentley/ecsdemo-frontend.git
#git clone https://github.com/brentley/ecsdemo-nodejs.git
#git clone https://github.com/brentley/ecsdemo-crystal.git
#git clone https://github.com/aws-samples/aws2tf.git

source ~/.bash_profile

#aws --version
#eksctl version
#kubectl version --client
#helm version

cd $this
