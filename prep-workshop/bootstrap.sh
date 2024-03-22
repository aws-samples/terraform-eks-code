export REPOSITORY_OWNER="aws-samples"
export REPOSITORY_NAME="eks-workshop-v2"
export REPOSITORY_REF="main"
rm -f installer.sh setup.sh
wget https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/lab/scripts/installer.sh
wget https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/lab/scripts/setup.sh
sed -i'.orig.' "s/set -e/#set -e/" installer.sh
chmod +x installer.sh
chmod +x setup.sh
sudo ./installer.sh
ls -l / | grep eks-workshop | grep ec2  > /dev/null
if [ $? -eq 0 ]; then
    sudo ./local.sh
    ./setup.sh
else
    echo "Root installer.sh may have failed"
fi
echo "Now run...."
echo "source ~/.bashrc"
