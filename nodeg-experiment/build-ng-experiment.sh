echo "circa 24m to complete"
./setup-ng.sh
time eksctl -v 4 create nodegroup -f manng-nodegroup.yml
