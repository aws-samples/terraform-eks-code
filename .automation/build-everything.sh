date
cur=`pwd`
#dirs="tf-setup net iam c9net cluster nodeg cicd eks-cidr lb2 sampleapp"
dirs="tf-setup net iam c9net cluster nodeg cicd eks-cidr lb2 sampleapp extra/nodeg2 extra/eks-cidr2 extra/sampleapp2"
for i in $dirs; do
cd $cur
cd ../$i
echo " "
echo "**** Building in $i ****"
rm -rf .terraform
terraform init -no-color
rc=0
terraform state list 2> /dev/null | grep aws_ > /dev/null
if [ $? -eq 0 ]; then
rc=$(terraform state list | wc -l ) 
fi
if [ "$i" == "tf-setup" ] && [ $rc -ge 12 ]; then echo "$rc in tf state expected 12" && continue; fi
if [ "$i" == "net" ] && [ $rc -ge 42 ]; then echo "$rc in tf state expected 42" && continue; fi
if [ "$i" == "iam" ] && [ $rc -ge 20 ]; then echo "$rc in tf state expected 20" && continue; fi
if [ "$i" == "c9net" ] && [ $rc -ge 34 ]; then echo "$rc in tf state expected 34" && continue; fi
if [ "$i" == "cluster" ] && [ $rc -ge 8 ]; then echo "$rc in tf state expected 8" && continue; fi
if [ "$i" == "nodeg" ] && [ $rc -ge 7 ]; then echo "$rc in tf state expected 7" && continue; fi
if [ "$i" == "cicd" ] && [ $rc -ge 25 ]; then echo "$rc in tf state expected 25" && continue; fi
if [ "$i" == "eks-cidr" ] && [ $rc -ge 7 ]; then echo "$rc in tf state expected 7" && continue; fi
if [ "$i" == "lb2" ] && [ $rc -ge 7 ]; then echo "$rc in tf state expected 7" && continue; fi
if [ "$i" == "sampleapp" ] && [ $rc -ge 7 ]; then echo "$rc in tf state expected 7" && continue; fi
if [ "$i" == "extra/nodeg2" ] && [ $rc -ge 7 ]; then echo "$rc in tf state expected 7" && continue; fi
if [ "$i" == "extra/eks-cidr2" ] && [ $rc -ge 7 ]; then echo "$rc in tf state expected 7" && continue; fi
if [ "$i" == "extra/sampleapp2" ] && [ $rc -ge 8 ]; then echo "$rc in tf state expected 8" && continue; fi
terraform plan -out tfplan -no-color
terraform apply tfplan -no-color
rc=$(terraform state list | wc -l)
if [ "$i" == "tf-setup" ] && [ $rc -lt 12 ]; then echo "only $rc in tf state expected 12" && break; fi
if [ "$i" == "net" ] && [ $rc -lt 42 ]; then echo "only $rc in tf state expected 42" && break; fi
if [ "$i" == "iam" ] && [ $rc -lt 20 ]; then echo "only $rc in tf state expected 20" && break; fi
if [ "$i" == "c9net" ] && [ $rc -lt 34 ]; then echo "only $rc in tf state expected 34" && break; fi
if [ "$i" == "cluster" ] && [ $rc -lt 8 ]; then echo "only $rc in tf state expected 8" && break; fi
if [ "$i" == "nodeg" ] && [ $rc -lt 7 ]; then echo "only $rc in tf state expected 7" && break; fi
if [ "$i" == "cicd" ] && [ $rc -lt 25 ]; then echo "only $rc in tf state expected 25" && break; fi
if [ "$i" == "eks-cidr" ] && [ $rc -lt 7 ]; then echo "only $rc in tf state expected 7" && break; fi
if [ "$i" == "lb2" ] && [ $rc -lt 7 ]; then echo "only $rc in tf state expected 7" && break; fi
# double check the helm chart has gone in
if [ "$i" == "lb2" ] ; then
    hc=$(helm ls -A | wc -l )
    if [ $hc -lt 2 ]; then
        echo "retry helm chart"
        terraform state rm helm_release.aws-load-balancer-controller
        terraform plan -out tfplan
        terraform apply tfplan
    fi
fi
if [ "$i" == "sampleapp" ] && [ $rc -lt 7 ]; then echo "only $rc in tf state expected 7" && break; fi
if [ "$i" == "extra/nodeg2" ] && [ $rc -lt 7 ]; then echo "only $rc in tf state expected 7" && break; fi
if [ "$i" == "extra/eks-cidr2" ] && [ $rc -lt 7 ]; then echo "only $rc in tf state expected 7+" && break; fi
if [ "$i" == "extra/sampleapp2" ] && [ $rc -lt 8 ]; then echo "only $rc in tf state expected 8" && break; fi
echo "Passed $i tests"
cd $cur
date
done
echo "Some post build verifications"
echo "Should have 23 pods running in total"
rc=$(kubectl get pods -A | grep Running | wc -l)
if [ $rc -lt 23 ]; then 
echo "ERROR: Found only $rc pods running - expected 23"
else
echo "Passed running pod count"
fi

# terraform state rm helm_release.aws-load-balancer-controller
# helm ls -A | wc -l
# 
