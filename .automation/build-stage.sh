if [ $1 = "" ];then
echo "must provide a stage directory .. exiting"
fi 
date

cur=`pwd`
buildok=1
rc=0

dirs=$1
for i in $dirs; do
    cd $cur
    cd ../$i
    echo " "
    echo "**** Building in $i ****"
    tobuild=$(grep 'data\|resource' *.tf | grep '"' | grep  '{' | cut -f2 -d ':' | grep -v '#\|=' | grep aws_ |  wc -l)
    terraform state list 2> /dev/null | grep aws_ > /dev/null
    if [ $? -eq 0 ]; then
        rc=$(terraform state list | grep aws_ | wc -l ) 
    fi
    if [ $rc -ge $tobuild ]; then echo "$rc in tf state expected $tobuild so skipping build ..." && continue; fi
    
    rm -rf .terraform* backend.tf
    echo "Terraform Init"
    #terraform init -no-color -force-copy -lock=false > /dev/null
    terraform init -no-color -force-copy > /dev/null
    rc=0

    # array elements in hetre so special rule
    
    echo "Terraform Plan"
    terraform plan -out tfplan -no-color > /dev/null
    terraform apply tfplan -no-color && terraform init -force-copy -no-color
    echo "State to S3. ."


    rc=$(terraform state list | grep aws_ | wc -l)
    
    # double check the helm chart has gone in
    if [ "$i" == "lb2" ] ; then
        hc=$(helm ls -A | wc -l )
        if [ $hc -lt 2 ]; then
            echo "retry helm chart"
            terraform state rm helm_release.aws-load-balancer-controller
            terraform plan -out tfplan -no-color
            terraform apply tfplan -no-color && terraform init -force-copy -no-color
            
        fi
    fi
    if [ $rc -lt $tobuild ]; then echo "only $rc in tf state expected $tobuild .. exit .." && exit; fi

    #echo "check state counts"
    #rsc=`terraform state list | wc -l`
    #lsc=`terraform state list -state=terraform.tfstate | wc -l`
    #echo "$rsc $lsc"
    #if [ $rsc -ne $lsc ]; then
    #    echo "Remote state != local state count ... exit ..."
    #    exit
    #fi

    echo "PASSED: $i tests"
    cd $cur
    
done


