echo "kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

echo "update aws cli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -f awscliv2.zip
rm -rf aws
#sudo pip install --upgrade awscli && hash -r

echo "other tools"
sudo yum -y install jq moreutils gettext bash-completion wget nmap bind-utils

echo 'yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq yq "$@"
}' | tee -a ~/.bash_profile && source ~/.bash_profile


echo "Terraform"
wget https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip
unzip -qq terraform_0.12.29_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm -f terraform_0.12.29_linux_amd64.zip


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
tar -zxvf helm-v3.2.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm-v3.2.1-linux-amd64.tar.gz linux-amd64
echo "add a repo"
helm repo add stable https://kubernetes-charts.storage.googleapis.com/


echo "kubectx"
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

echo "install go"
wget https://dl.google.com/go/go1.12.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.12.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=$PATH:/usr/local/go/bin" | tee -a ~/.bash_profile
rm -f go1.12.5.linux-amd64.tar.gz

echo "verify"
for command in kubectl jq envsubst aws wget terraform eksctl go helm kubectx
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done


echo "install krew"

curl -fsSLO "https://storage.googleapis.com/krew/v0.2.1/krew.{tar.gz,yaml}"
tar zxvf krew.tar.gz 
./krew-linux_amd64 install --manifest=krew.yaml --archive=krew.tar.gz

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
echo "export PATH=${KREW_ROOT:-$HOME/.krew}/bin:$PATH" | tee -a ~/.bash_profile
rm -f krew*
rm -rf linux-amd64
kubectl krew install access-matrix
kubectl krew install rbac-lookup

go get -v github.com/aquasecurity/kubectl-who-can
kubectl krew install who-can


this=`pwd`
echo "sample apps"
cd ~/environment
git clone https://github.com/brentley/ecsdemo-frontend.git
git clone https://github.com/brentley/ecsdemo-nodejs.git
git clone https://github.com/brentley/ecsdemo-crystal.git
git clone https://github.com/awsandy/aws2tf.git

source ~/.bash_profile

aws --version
eksctl version
kubectl version --client
helm version
yq --version


cd $this


#echo "Configure Cloud 9 & AWS Settings - then run part2.sh"

