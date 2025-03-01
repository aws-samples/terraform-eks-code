export REPOSITORY_OWNER="aws-samples"
export REPOSITORY_NAME="eks-workshop-v2"
export REPOSITORY_REF="main"
#sudo yum install -y jq  amazon-ec2-utils
export AWS_REGION=$(ec2-metadata | grep local-hostname | cut -f2 -d'.')
#rm -f installer.sh setup.sh
#wget https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/lab/scripts/installer.sh &>/dev/null
#wget https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/lab/scripts/setup.sh &>/dev/null
#sed -i'.orig.' "s/set -e/#set -e/" installer.sh
chmod +x installer.sh
#chmod +x setup.sh
echo "Running installer.sh ....."
sudo ./installer.sh
#ls -l / | grep eks-workshop | grep ec2 >/dev/null
#if [ $? -eq 0 ]; then
#    echo "Install utils into /usr/local/bin"
#    sudo ./local.sh
#    echo "Setup local bash environment ....."
#    ./setup.sh
#else
#    echo "Root installer.sh may have failed"
#fi
aws configure set default.region $AWS_REGION
aws configure set region $AWS_REGION
echo "Add SPOT service linked role"
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com &> /dev/null || true
echo "Now run...."
echo " "
echo "source ~/.bashrc"
