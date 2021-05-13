date
cur=`pwd`
#dirs="tf-setup net iam c9net cluster nodeg cicd eks-cidr lb2 sampleapp"
dirs="tf-setup net iam c9net cluster nodeg cicd eks-cidr lb2 sampleapp extra/nodeg2 extra/eks-cidr2 extra/sampleapp2"
for i in $dirs; do
    cd $cur
    cd ../$i
    echo " "
    echo "**** Building in $i ****"
    tobuild=$(grep 'data\|resource' *.tf | grep '"' | grep  '{' | grep -v '#' |  wc -l)
    rm -rf .terraform*
    terraform init -no-color > /dev/null
    rc=0
    terraform state list 2> /dev/null | grep aws_ > /dev/null
    if [ $? -eq 0 ]; then
        rc=$(terraform state list | wc -l ) 
    fi
    # array elements in hetre so special rule
    if [ "$i" == "tf-setup" ] && [ $rc -ge 12 ]; then echo "$rc in tf state expected 12 so skipping build ..." && continue; fi
    if [ $rc -ge $tobuild ]; then echo "$rc in tf state expected $tobuild so skipping build ..." && continue; fi
    
    terraform plan -out tfplan -no-color
    terraform apply tfplan -no-color
    rc=$(terraform state list | wc -l)
  
    if [ "$i" == "tf-setup" ] && [ $rc -lt 12 ]; then echo "only $rc in tf state expected 12" && break; fi
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
    if [ $rc -lt $tobuild ]; then echo "only $rc in tf state expected $tobuild" && break; fi
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
echo "PASSED: running pod count $rc"
fi

# terraform state rm helm_release.aws-load-balancer-controller
# helm ls -A | wc -l
# 
