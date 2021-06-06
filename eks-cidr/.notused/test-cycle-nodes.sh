ncount=$(kubectl get nodes -o json | jq ".items | length - 1" )
echo "num nodes=$ncount"
for k in `seq 0 $ncount`; do
    nn=$(kubectl get nodes -o json | jq -r .items[$k].metadata.name)
    echo $nn
    inst=$(aws ec2  describe-network-interfaces --region $AWS_REGION --filters Name=private-dns-name,Values=$nn --query 'NetworkInterfaces[0].Attachment.InstanceId' | jq -r .)
    echo "inst = $inst" 
    nifs=$(aws ec2  describe-network-interfaces --region $AWS_REGION --filters Name=attachment.instance-id,Values=$inst --query 'NetworkInterfaces')
    count=$(echo $nifs | jq ". | length - 1" )
    echo $count

    #kubectl drain $nn
    #kubectl drain $nn --delete-local-data --ignore-daemonsets
    #sleep 5
    #kubectl get nodes



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
            

            dl=()
                #ssh ec2-user@$nn "sudo systemctl stop kubelet"
            dl+=$(ssh ec2-user@$nn "sudo docker ps -aq")
            for k in ${dl[@]}; do
                echo "docker stop $k"
                #ssh ec2-user@$nn "sudo docker stop $k"
                #ssh ec2-user@$nn "hostname"
            done
            ssh ec2-user@$nn "hostname"
            #ssh ec2-user@$nn "sudo systemctl stop docker"
            
            echo "private ip's $ips"
            if [ "$ips" != "" ];then 
                echo "unassign --network-interface-id $nid --private-ip-addresses $ips"
                #aws ec2 unassign-private-ip-addresses --region eu-west-2 --network-interface-id $nid --private-ip-addresses $ips
            fi
### Now restart the node
            echo "inside retart"
            if [ "$pubdns" != "null" ];then 
                #ssh ec2-user@$nn "sudo systemctl start docker"
                #ssh ec2-user@$nn "sudo systemctl start kubelet"
                ssh ec2-user@$nn "hostname"
            fi
        done
    fi

    #kubectl uncordon $nn
    #sleep 5
    #kubectl get nodes
    echo "outside restart"
    ssh ec2-user@$nn "hostname"
    echo "*** $nn finished ****"
    kubectl get nodes
done