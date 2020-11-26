

echo "update aws cli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -f awscliv2.zip
rm -rf aws
#sudo pip install --upgrade awscli && hash -r

echo "other tools"
sudo yum -y install moreutils jq gettext bash-completion wget nmap bind-utils


echo "Terraform"
wget https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_linux_amd64.zip
unzip -qq terraform_0.12.28_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm -f terraform_0.12.28_linux_amd64.zip


echo "ssh key"
mkdir -p ~/.ssh
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
chmod 600 ~/.ssh/id*
aws ec2 delete-key-pair --key-name "networkshop"
aws ec2 import-key-pair --key-name "networkshop" --public-key-material fileb://~/.ssh/id_rsa.pub



echo "verify"
for command in jq aws wget terraform eksctl
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done




this=`pwd`
echo "sample apps"
cd ~/environment
git clone https://github.com/aws-samples/aws2tf.git

source ~/.bash_profile

sudo pip install terrascan

# SSM add on
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
sudo yum install -y session-manager-plugin.rpm
session-manager-plugin

aws --version

cd $this

echo "Configure Cloud 9 & AWS Settings"



