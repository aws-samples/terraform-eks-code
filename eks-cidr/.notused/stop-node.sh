ncount=$(kubectl get nodes -o json | jq ".items | length - 1" )
echo $ncount
for k in `seq 0 $ncount`; do
nn=$(kubectl get nodes -o json | jq -r .items[$k].metadata.name)
echo $nn
inst=$(aws ec2  describe-network-interfaces --region eu-west-2 --filters Name=private-dns-name,Values=$nn --query 'NetworkInterfaces[0].Attachment.InstanceId' | jq -r .)
echo $inst 
nifs=$(aws ec2  describe-network-interfaces --region eu-west-2 --filters Name=attachment.instance-id,Values=$inst --query 'NetworkInterfaces')
count=$(echo $nifs | jq ". | length - 1" )
echo $count

kubectl drain $nn
kubectl drain $nn --delete-local-data --ignore-daemonsets
sleep 5
kubectl get nodes



if [ "$count" -ge "0" ]; then
    for i in `seq 0 $count`; do
        echo "Net if $i"
        nid=$(echo $nifs | jq -r ".[$i].NetworkInterfaceId")
        echo $nid
        ips=()
        ips+=$(echo $nifs | jq -r ".[$i].PrivateIpAddresses[] | select(.Primary==false) | .PrivateIpAddress" )
        #for j in ${ips[@]}; do
        #echo $j
        #done
        #echo "aws ec2 unassign-private-ip-addresses --region eu-west-2 --network-interface-id $nid --private-ip-addresses $ips"
        #echo $nifs | jq .       
        pubdns=$(echo $nifs | jq -r ".[$i].PrivateIpAddresses[] | select(.Primary==true) | .Association.PublicDnsName")
        echo "pub dns=$pubdns"
        if [ "$pubdns" != "null" ];then 
            dl=()
            ssh ec2-user@$pubdns "sudo systemctl stop kubelet"
            dl+=$(ssh ec2-user@$pubdns "sudo docker ps -aq")
            for k in ${dl[@]}; do
                echo "docker stop $k"
                ssh ec2-user@$pubdns "sudo docker stop $k"
            done
            ssh ec2-user@$pubdns "sudo docker ps"
            ssh ec2-user@$pubdns "sudo systemctl stop docker"
        fi
        echo "private ip's $ips"
        if [ "$ips" != "" ];then 
            aws ec2 unassign-private-ip-addresses --region eu-west-2 --network-interface-id $nid --private-ip-addresses $ips
        fi
    done
fi

done