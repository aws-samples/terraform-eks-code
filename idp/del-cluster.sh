aws cloudformation delete-stack --stack-name eksctl-cnoe-ref-impl-addon-aws-ebs-csi-driver
echo "deleting stack  eksctl-cnoe-ref-impl-addon-aws-ebs-csi-driver ...."
aws cloudformation wait stack-delete-complete --stack-name eksctl-cnoe-ref-impl-addon-aws-ebs-csi-driver
#
aws cloudformation delete-stack --stack-name eksctl-cnoe-ref-impl-nodegroup-managed-ng-1
echo "deleting stack  eksctl-cnoe-ref-impl-nodegroup-managed-ng-1 ...."
aws cloudformation wait stack-delete-complete --stack-name eksctl-cnoe-ref-impl-nodegroup-managed-ng-1
#
aws cloudformation delete-stack --stack-name eksctl-cnoe-ref-impl-addon-iamserviceaccount-kube-system-aws-node
echo "deleting stack  eksctl-cnoe-ref-impl-addon-iamserviceaccount-kube-system-aws-node ...."
aws cloudformation wait stack-delete-complete --stack-name eksctl-cnoe-ref-impl-addon-iamserviceaccount-kube-system-aws-node
#
aws cloudformation delete-stack --stack-name eksctl-cnoe-ref-impl-cluster
echo "deleting stack  eksctl-cnoe-ref-impl-cluster ...."
aws cloudformation wait stack-delete-complete --stack-name eksctl-cnoe-ref-impl-cluster
echo "Done."
