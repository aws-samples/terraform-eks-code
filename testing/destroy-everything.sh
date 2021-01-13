echo "Pre cli based actions ..."
userid=$(aws iam list-service-specific-credentials --user-name git-user | jq -r .ServiceSpecificCredentials[0].ServiceSpecificCredentialId)
if [ "$userid" != "null" ]; then
aws iam delete-service-specific-credential --service-specific-credential-id $userid --user-name git-user
fi
# lb, lb sg, launch template
echo "pass 1 ...."
cur=`pwd`
date
dirs="sampleapp cicd nodeg cluster c9net iam net tf-setup"
for i in $dirs; do
cd ../$i
echo "**** Destroying in $i ****"
terraform destroy -auto-approve
cd $cur
date
done
echo "Pass 1 cli based actions ..."
echo "pass 2 ...."
for i in $dirs; do
cd ../$i
echo "**** Destroying in $i ****"
terraform destroy -auto-approve
rm -rf .terraform
rm -f terraform.tfstate* tfplan
cd $cur
date
done
echo "Pass 2 cli based actions ..."
echo "Done"
exit