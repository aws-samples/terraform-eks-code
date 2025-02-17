export AWS_REGION="eu-west-1"
export REPOSITORY_OWNER="aws-samples"
export REPOSITORY_NAME="eks-workshop-v2"
export REPOSITORY_REF="main"
wget https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/lab/scripts/installer.sh
wget https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/lab/scripts/setup.sh
curl -fsSL https://raw.githubusercontent.com/${RepositoryOwner}/${RepositoryName}/${RepositoryRef}/lab/scripts/installer.sh | bash
sudo -E -H -u ec2-user bash -c "curl -fsSL https://raw.githubusercontent.com/${RepositoryOwner}/${RepositoryName}/${RepositoryRef}/lab/scripts/setup.sh | bash"