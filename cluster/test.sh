resp=$(aws eks describe-cluster --name $1)
endp=$(echo $resp | jq -r .cluster.endpoint | cut -f3 -d'/')
#nslookup $endp
nmap $endp -Pn -p 443