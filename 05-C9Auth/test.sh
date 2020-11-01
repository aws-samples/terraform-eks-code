cn=`terraform output cluster-name`
resp=$(aws eks describe-cluster --name mycluster1)
endp=$(echo $resp | jq -r .cluster.endpoint | cut -f3 -d'/')
nslookup $endp
nmap $endp -Pn -p 443