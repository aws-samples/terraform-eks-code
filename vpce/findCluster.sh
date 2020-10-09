#!/bin/bash

# Exit if any of the intermediate steps fail
set -e
if [[ -z "${CLUSTER}" ]]; then
    i=0
    clusters=()
    # find the cluster
    clusters+=(`$AWS eks list-clusters | jq .clusters[] --compact-output`)
    #for j in `aws --region eu-west-2 eks list-clusters | jq .clusters[]`; do
    #echo "j=$j"
    #clusters+=($j)
    #done
    nc=${#clusters[@]}
    #echo "array size=$nc"
    #echo ${clusters[0]}
    #echo ${clusters[1]}

    if [ $nc != "1" ]; then
        echo "pick a cluster by setting the CLUSTER environment varibale"
        exit
    else
        CLUSTER=`echo ${clusters[0]} | tr -d '"'`
        #echo $CLN
    fi
fi
jq -n --arg cln "$CLUSTER" '{"Name":$cln}'
