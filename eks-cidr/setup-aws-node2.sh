export AZ1=$(echo $1)
export AZ2=$(echo $2)
export AZ3=$(echo $3)
export CUST_SNET1=$(echo $4)
export CUST_SNET2=$(echo $5)
export CUST_SNET3=$(echo $6)
export SG1=$(echo $7)
export SG2=$(echo $8)

echo "$AZ1 $AZ2 $AZ3"
echo "$CUST_SNET1 $CUST_SNET2 $CUST_SNET3"
echo "$SG1 $SG2"
#
#
#To create an ENIConfig custom resource for all subnets and Availability Zones, run the following commands:
exit
cat <<EOF  | kubectl apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: $AZ1
spec:
  subnet: $CUST_SNET1
EOF

cat <<EOF | kubectl apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: $AZ2
spec:
  subnet: $CUST_SNET2
EOF

cat <<EOF | kubectl apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: $AZ3
spec:
  subnet: $CUST_SNET3
EOF


