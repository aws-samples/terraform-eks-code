echo "Pre cli based actions ..."
userid=$(aws iam list-service-specific-credentials --user-name git-user 2> /dev/null | jq -r .ServiceSpecificCredentials[0].ServiceSpecificCredentialId)
if [ "$userid" != "null" ]; then
    echo "destroying git user credentaisl for $userid"
    aws iam delete-service-specific-credential --service-specific-credential-id $userid --user-name git-user &> /dev/null
fi
helm uninstall keycloak -n keycloak &> /dev/null
kubectl delete ns keycloak &> /dev/null
kubectl delete ns sample &> /dev/null
kubectl delete ns ui &> /dev/null
kubectl delete ns assets &> /dev/null
kubectl delete ns catalog &> /dev/null
kubectl delete ns checkout &> /dev/null
kubectl delete ns carts &> /dev/null
kubectl delete ns orders &> /dev/null
kubectl delete ns rabbitmq &> /dev/null
flux uninstall -s &> /dev/null
# Empty codepipeline bucket ready for delete
buck=$(aws s3 ls | grep codep-tfeks | awk '{print $3}')
echo "buck=$buck"
if [ "$buck" != "" ]; then
    echo "Emptying bucket $buck"
    comm=$(printf "aws s3 rm s3://%s --recursive" $buck)
    eval $comm  &> /dev/null
fi
#
# lb, lb sg, launch template

set -e # turn on error checking - exit if error
echo "pass 1 ...."
cur=$(pwd)
date
#dirs="extra/.karpenter extra/fargateapp extra/fargate extra/sampleapp2 extra/eks-cidr2 extra/nodeg2 sampleapp lb2 cicd nodeg cluster c9net iam net"
dirs="istio keycloak observ addons cluster c9net net"
for i in $dirs; do
    cd $cur
    cd ../$i
    if [[ -d .terraform ]]; then
        echo "**** Destroying in $i ****"
        terraform destroy -auto-approve
        if [[ $? -eq 0 ]];then
            rm -rf .terrform*
        fi
    fi
    cd $cur
    date
done
echo "Pass 1 cli based actions ..."
#echo "pass 2 ...."
#for i in $dirs; do
#cd $cur
#cd ../$i
#echo "**** Destroying in $i ****"
#terraform destroy -auto-approve 2&> /dev/null
#rm -f tfplan terraform*
#rm -rf .terraform
#cd $cur
#date
#done
dirs="tf-setup"
for i in $dirs; do
    cd ../$i
    echo "**** Destroying in $i ****"
    terraform destroy -auto-approve >/dev/null
    #rm -f tfplan terraform*
    #rm -rf .terraform
    cd $cur
    date
done
echo "Done"
set +e # turn off error checking 
exit
