#!/bin/bash

# Exit if any of the intermediate steps fail
set -e
i=0
clusters=()
# find the cluster
#clusters+=(`aws --profile Pub1 --region eu-west-2 eks list-clusters | jq .clusters[] --compact-output`)
clusters=`terraform state show data.terraform_remote_state.cluster | grep cluster-name | cut -f2 -d'=' | tr -d '"'`

nc=${#clusters[@]}
c9role=`terraform output c9role`
echo $c9role

#echo "array size=$nc"
#echo ${clusters[0]}
#echo ${clusters[1]}

if [ $nc != "1" ]; then
echo "pick cluster"
exit
else
CLN=`echo ${clusters[0]} | tr -d '"'`
#echo $CLN
jq -n --arg cln "$CLN" '{"Name":$cln}'
fi

