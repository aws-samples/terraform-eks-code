if [ $1 = "" ]; then
    echo "must provide a stage directory .. exiting"
fi
date

cur=$(pwd)
buildok=1
rc=0

dirs=$1
for i in $dirs; do
    cd $cur
    cd ../$i
    echo " "
    echo "**** Building in $i ****"
    rm -rf .terraform* backend.tf
    echo "Terraform Init"
    #terraform init -no-color -force-copy > /dev/null
    terraform init -no-color >/dev/null
    rc=0
    tobuild=$(terraform plan -json -out tfplan | jq '.changes' | grep -v null | jq .add | tail -1)
    echo "tobuild = $tobuild"
    if [[ $tobuild -gt 0 ]]; then
        terraform state list 2>/dev/null | grep aws_ >/dev/null
        if [ $? -eq 0 ]; then
            rc=$(terraform state list | grep aws_ | wc -l)
        fi
        if [ $rc -ge $tobuild ]; then echo "$rc in tf state expected $tobuild so skipping build ..." && continue; fi

        # array elements in here so special rule

        #echo "Terraform Plan"
        #pc=$(terraform plan -json -out tfplan | jq '.changes' | grep -v null | jq .add | tail -1)
        terraform apply tfplan -no-color -json

        #terraform apply tfplan -no-color && terraform init -force-copy -no-color
        #echo "State to S3. ."
        #terraform init -force-copy -no-color

        rc=$(terraform state list | grep aws_ | wc -l)

    # double check the helm chart has gone in
    fi
    if [ $rc -lt $tobuild ]; then echo "only $rc in tf state expected $tobuild .. exit .." && exit; fi

    echo "PASSED $i tests (found $rc resources expected minimum for this stage = $tobuild)"
    cd $cur

done
