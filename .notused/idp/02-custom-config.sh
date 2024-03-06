cd ~/environment/idp/setups
echo "change config.yaml"
acc=$(aws sts get-caller-identity --query Account --output text)
reg=$(aws ssm get-parameter --name /workshop/tf-eks/region --query Parameter.Value --output text)
cln=$(aws ssm get-parameter --name /workshop/tf-eks/cluster-name --query Parameter.Value --output text)
hzn=$(aws ssm get-parameter --name /workshop/tf-eks/phz-id --query Parameter.Value --output text)
domain=$(echo $acc.awsandy.people.aws.dev)
cp config.yaml config.yaml.saved
cmd=$(printf "sed -i'.orig' -e 's/us-west-2/%s/g' config.yaml" $reg)
eval $cmd
cmd=$(printf "sed -i'.orig' -e 's/cnoe-ref-impl/%s/g' config.yaml" $cln)
eval $cmd
cmd=$(printf "sed -i'.orig' -e 's/Z0REPLACEME/%s/g' config.yaml" $hzn)
eval $cmd
cmd=$(printf "sed -i'.orig' -e 's/sudbomain.domain.root/%s/g' config.yaml" $domain)
eval $cmd
cmd=$(printf "sed -i'.orig' -e 's/: true/: false/g' config.yaml")
eval $cmd
# stop cert manager install:
