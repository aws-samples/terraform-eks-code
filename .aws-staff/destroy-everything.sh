echo "Pre cli based actions ..."
userid=$(aws iam list-service-specific-credentials --user-name git-user 2>/dev/null | jq -r .ServiceSpecificCredentials[0].ServiceSpecificCredentialId)
if [ "$userid" != "" ]; then
    echo "destroying git user credentails for $userid"
    aws iam delete-service-specific-credential --service-specific-credential-id $userid --user-name git-user &>/dev/null
fi
kubectl version &>/dev/null
if [[ $? -eq 0 ]]; then
    echo "zap std app"
    kubectl delete ns sample &>/dev/null
    kubectl delete ns ui &>/dev/null
    kubectl delete ns assets &>/dev/null
    kubectl delete ns catalog &>/dev/null
    kubectl delete ns checkout &>/dev/null
    kubectl delete ns carts &>/dev/null
    kubectl delete ns orders &>/dev/null
    kubectl delete ns rabbitmq &>/dev/null
    echo "zap Flux"
    flux uninstall -s &>/dev/null
    sleep 2
fi

# Empty codepipeline bucket ready for delete
buck=$(aws s3 ls | grep codep-tfeks | awk '{print $3}')
if [ "$buck" != "" ]; then
    echo "Emptying bucket $buck"
    comm=$(printf "aws s3 rm s3://%s --recursive" $buck)
    eval $comm &>/dev/null
fi
#
# lb, lb sg, launch template

#set -e # turn on error checking - exit if error
echo "pass 1 ...."
cur=$(pwd)
date
dirs="istio observ sampleapp addons nodepool"
for i in $dirs; do
    cd $cur
    cd ../$i
    echo "**** Destroying in $i ****"
    if [[ -d ".terraform" ]]; then
        echo "**** terraform destroy in $i ****"
        terraform destroy -auto-approve 2 &>/dev/null
        if [[ $? -ne 0 ]]; then
            rm -rf .terraform*
            echo "Init ..."
            terraform init -upgrade >/dev/null
            if [[ $? -ne 0 ]]; then
                mv backend-$i.tf backend-$i.tf.sav
                echo "moved backend & Init ..."
                terraform init -reconfigure
            fi
            terraform destroy -auto-approve
            if [[ $? -eq 0 ]]; then
                echo "terraform destroy in $i succeeded"
                #rm -rf .terraform*
            else
                echo "terraform destroy in $i failed"
                exit
            fi
        else
            echo "terraform destroy in $i succeeded"
            rm -rf .terraform*
        fi
    else
        echo "no .terraform directory found skipping ..."
    fi
    cd $cur
    date
done

dirs="cluster"
for i in $dirs; do
    cd ../$i
    echo "**** Destroying in $i ****"
    if [[ -d ".terraform" ]]; then
        #kubectl delete ns amazon-cloudwatch
        #kubextl delete deployment ebs-csi-controller -n kube-system
        #terraform destroy -target module.eks.aws_eks_addon.aws-ebs-csi-driver -auto-approve
        #terraform destroy -target amazon-cloudwatch-observability -auto-approve
        echo "EKS Cluster delete ~3m"
        terraform destroy -target module.eks.aws_eks_cluster.this -auto-approve
        terraform destroy -target module.eks -auto-approve
        terraform destroy -auto-approve 
        if [[ $? -eq 0 ]]; then
            rm -f tfplan terraform*
            rm -rf .terraform
        else
            exit
        fi
    fi
    cd $cur
    date
done
dirs="net tf-setup"
for i in $dirs; do
    cd ../$i
    echo "**** Destroying in $i ****"
    if [[ -d ".terraform" ]]; then
        terraform destroy -auto-approve >/dev/null
        rm -f tfplan terraform*
        #rm -rf .terraform
    fi
    cd $cur
    date
done
echo "Done"
#set +e # turn off error checking
