nn=$(kubectl get nodes -o json | jq -r .items[0].metadata.name)
echo $nn
inst=$(aws ec2  describe-network-interfaces --region eu-west-2 --filters Name=private-dns-name,Values=$nn --query 'NetworkInterfaces[0].Attachment.InstanceId' | jq -r .)
echo $inst 
nifs=$(aws ec2  describe-network-interfaces --region eu-west-2 --filters Name=attachment.instance-id,Values=$inst --query 'NetworkInterfaces')
count=$(echo $nifs | jq ". | length - 1" )
echo $count

if [ "$count" -ge "0" ]; then
    for i in `seq 0 $count`; do
        echo "Net if $i"
        nid=$(echo $nifs | jq -r ".[$i].NetworkInterfaceId")
        echo $nid
        #for j in ${ips[@]}; do
        #echo $j
        #done
        #echo "aws ec2 unassign-private-ip-addresses --region eu-west-2 --network-interface-id $nid --private-ip-addresses $ips"
        #echo $nifs | jq .       
        pubdns=$(echo $nifs | jq -r ".[$i].PrivateIpAddresses[] | select(.Primary==true) | .Association.PublicDnsName")
        echo "pub dns=$pubdns"
        if [ "$pubdns" != "null" ];then 
            ssh ec2-user@$pubdns "sudo systemctl start docker"
            ssh ec2-user@$pubdns "sudo systemctl start kubelet"

        fi

    done
fi


kubectl uncordon $nn
sleep 5
kubectl get nodes
ssh ec2-user@$pubdns "sudo docker ps"