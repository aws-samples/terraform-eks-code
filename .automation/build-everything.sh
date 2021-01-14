date
cur=`pwd`
dirs="tf-setup net iam c9net cluster nodeg cicd eks-cidr lb2 sampleapp"
#dirs="tf-setup net iam c9net cluster nodeg cicd eks-cidr lb2 sampleapp extra/nodeg2 extra/eks-cidr2 extra/sampleapp2"
for i in $dirs; do
cd ../$i
echo " "
echo "**** Building in $i ****"
rm -rf .terraform
rm -f terraform.tfstate* tfplan
terraform init -no-color
terraform plan -out tfplan -no-color
terraform apply tfplan -no-color
rc=$(terraform state list | wc -l)
if [ "$i" == "tf-setup" ] && [ "$rc" != 12 ]; then echo "only $rc in tf state expected 12" && break; fi
if [ "$i" == "net" ] && [ "$rc" != 42 ]; then echo "only $rc in tf state expected 42" && break; fi
if [ "$i" == "iam" ] && [ "$rc" != 20 ]; then echo "only $rc in tf state expected 20" && break; fi
if [ "$i" == "c9net" ] && [ "$rc" != 34 ]; then echo "only $rc in tf state expected 34" && break; fi
if [ "$i" == "cluster" ] && [ "$rc" != 8 ]; then echo "only $rc in tf state expected 8" && break; fi
if [ "$i" == "nodeg" ] && [ "$rc" != 7 ]; then echo "only $rc in tf state expected 7" && break; fi
if [ "$i" == "cicd" ] && [ "$rc" != 25 ]; then echo "only $rc in tf state expected 25" && break; fi
if [ "$i" == "eks-cidr" ] && [ "$rc" != 7 ]; then echo "only $rc in tf state expected 7" && break; fi
if [ "$i" == "lb2" ] && [ "$rc" != 7 ]; then echo "only $rc in tf state expected 7" && break; fi
if [ "$i" == "sampleapp" ] && [ "$rc" != 7 ]; then echo "only $rc in tf state expected 7" && break; fi
if [ "$i" == "extra/nodeg2" ] && [ "$rc" != 7 ]; then echo "only $rc in tf state expected 7" && break; fi
if [ "$i" == "extra/eks-cidr2" ] && [ "$rc" != 7 ]; then echo "only $rc in tf state expected 7" && break; fi
if [ "$i" == "extra/sampleapp2" ] && [ "$rc" != 8 ]; then echo "only $rc in tf state expected 8" && break; fi
cd $cur
date
done
echo "Some post build verifications"
echo "Should have 23 pods running in total"
rc=$(kubectl get pods -A | grep Running | wc -l)
if [ "$rc" != 23 ]; then 
echo "ERROR: Found only $rc pods running - expected 23"
else
echo "Passed"
fi
