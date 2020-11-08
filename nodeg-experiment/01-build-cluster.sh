echo "circa 24m to complete"
./setup-cluster.sh
time eksctl -v 4 create cluster -f manng-cluster.yml
