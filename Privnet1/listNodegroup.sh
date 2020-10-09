set -e
i=0
clusters=()
export AWS="aws --profile Pub1 --region eu-west-2"
# find the cluster
clusters+=(`aws --profile Pub1 --region eu-west-2 eks list-clusters | jq .clusters[] --compact-output`)
#for j in `aws --region eu-west-2 eks list-clusters | jq .clusters[]`; do
#echo "j=$j"
#clusters+=($j)
#done
nc=${#clusters[@]}

#echo "array size=$nc"
#echo ${clusters[0]}
#echo ${clusters[1]}

if [ $nc != "1" ]; then
echo "pick cluster"
exit
else
CLN=`echo ${clusters[0]} | tr -d '"'`
#echo $CLN
#jq -n --arg cln "$CLN" '{"Name":$cln}'
ng=`$AWS eks list-nodegroups --cluster-name $CLN | jq .nodegroups[0] | tr -d '"'`
#echo $ng
$AWS eks describe-nodegroup --cluster-name $CLN --nodegroup-name $ng
fi