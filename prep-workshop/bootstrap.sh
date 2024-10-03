export REPOSITORY_OWNER="aws-samples"
export REPOSITORY_NAME="eks-workshop-v2"
export REPOSITORY_REF="main"
sudo yum install -y jq 
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
rm -f installer.sh setup.sh
wget https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/lab/scripts/installer.sh &>/dev/null
wget https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/lab/scripts/setup.sh &>/dev/null
sed -i'.orig.' "s/set -e/#set -e/" installer.sh
chmod +x installer.sh
chmod +x setup.sh
echo "Running installer.sh ....."
(sudo ./installer.sh) &>/dev/null
ls -l / | grep eks-workshop | grep ec2 >/dev/null
if [ $? -eq 0 ]; then
    echo "Install utils into /usr/local/bin"
    sudo ./local.sh
    echo "Setup local bash environment ....."
    ./setup.sh
else
    echo "Root installer.sh may have failed"
fi
if [[ ! -z $C9_PID ]]; then
    TOKEN=$(curl -s --request PUT "http://169.254.169.254/latest/api/token" --header "X-aws-ec2-metadata-token-ttl-seconds: 3600")
    export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region --header "X-aws-ec2-metadata-token: $TOKEN")
    echo "Saving AWS_REGION=${AWS_REGION}"
    echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bashrc
    profile_name="eksworkshop-admin"
    instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id --header "X-aws-ec2-metadata-token: $TOKEN")
    ipa=$(aws ec2 describe-instances --instance-ids $instance_id --query Reservations[].Instances[].IamInstanceProfile | jq -r .[].Arn)
    iip=$(aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$instance_id" --query IamInstanceProfileAssociations[].AssociationId | jq -r .[])
    echo "Associate $profile_name"
    if aws ec2 replace-iam-instance-profile-association --iam-instance-profile "Name=$profile_name" --association-id $iip; then
        if aws cloud9 update-environment --environment-id $C9_PID --managed-credentials-action DISABLE 2>/dev/null; then
            rm -vf ${HOME}/.aws/credentials
            echo "Profile eksworkshop-admin associated successfully."
        fi
    else
        echo "ERROR: Encountered error associating instance profile eksworkshop-admin with Cloud9 environment"
    fi
    aws configure set default.region $AWS_REGION
    aws configure set region $AWS_REGION
fi
echo "Add SPOT service linked role"
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com &> /dev/null || true
echo "Now run...."
echo " "
echo "source ~/.bashrc"
