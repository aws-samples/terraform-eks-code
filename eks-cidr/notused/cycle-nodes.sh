test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || "echo AWS_REGION is not set && exit"
ncount=$(kubectl get nodes -o json | jq ".items | length - 1" )
echo $ncount
for k in `seq 0 $ncount`; do
    nn=$(kubectl get nodes -o json | jq -r .items[$k].metadata.name)
    echo "Starting $nn"
    inst=$(aws ec2  describe-network-interfaces --region $AWS_REGION --filters Name=private-dns-name,Values=$nn --query 'NetworkInterfaces[0].Attachment.InstanceId' | jq -r .)
    echo "inst=$inst" 
    if [ "$inst" == "null" ];then
        echo "no instance - exiting"
        exit
    fi
    nifs=$(aws ec2  describe-network-interfaces --region $AWS_REGION --filters Name=attachment.instance-id,Values=$inst --query 'NetworkInterfaces')
    count=$(echo $nifs | jq ". | length - 1" )
    echo "netif count =$count"


    echo "Soft Drain"
    kubectl drain $nn
    echo "Hard Drain"
    kubectl drain $nn --delete-local-data --ignore-daemonsets
    echo "sleep 10 for drain"
    sleep 10
    kubectl get nodes



    if [ "$count" -ge "0" ]; then
        for i in `seq 0 $count`; do
            echo "Net if $i"
            nid=$(echo $nifs | jq -r ".[$i].NetworkInterfaceId")
            echo $nid
            ips=()
            ips+=$(echo $nifs | jq -r ".[$i].PrivateIpAddresses[] | select(.Primary==false) | .PrivateIpAddress" )
      
                
            ssh ec2-user@$nn "sudo systemctl stop kubelet"
            dl=()
            dl+=$(ssh ec2-user@$nn "sudo docker ps -aq")
            for k in ${dl[@]}; do
                echo "docker stop $k"
                ssh ec2-user@$nn "sudo docker stop $k"
            done
            ssh ec2-user@$nn "sudo docker ps"
            ssh ec2-user@$nn "sudo systemctl stop docker"
            
            echo "private ip's $ips"
            if [ "$ips" != "" ];then 
                aws ec2 unassign-private-ip-addresses --region $AWS_REGION --network-interface-id $nid --private-ip-addresses $ips
            fi
### Now restart the node
            echo "Inside Restart"
            if [ "$pubdns" != "null" ];then 
                ssh ec2-user@$nn "sudo systemctl start docker"
                ssh ec2-user@$nn "sudo systemctl start kubelet"

            fi
        done
    fi

    kubectl uncordon $nn
    echo "sleep for uncordon"
    sleep 5
    kubectl get nodes
    kubectl get pods -A
    echo "Done $nn"

done