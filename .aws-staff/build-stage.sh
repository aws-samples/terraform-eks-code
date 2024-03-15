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
    terraform plan -json -out tfplan > tfplan.json
    tobuild=$(cat tfplan.json | jq '.changes' | grep -v null | jq .add | tail -1)
    toremove=$(cat tfplan.json | jq '.changes' | grep -v null | jq .remove | tail -1)
    echo "tobuild = $tobuild  toremove=$toremove"
    if [[ $tobuild -gt 0 ]]; then
        
        #if [[ $tobuild != $toremove ]]
        # array elements in here so special rule

        #echo "Terraform Plan"
        #pc=$(terraform plan -json -out tfplan | jq '.changes' | grep -v null | jq .add | tail -1)
        terraform apply tfplan -no-color -json > apply.json
        rc=$(cat apply.json | jq '.changes' | grep -v null | jq .add | tail -1)

        #terraform apply tfplan -no-color && terraform init -force-copy -no-color
        #echo "State to S3. ."
        #terraform init -force-copy -no-color

        #rc=$(terraform state list | grep aws_ | wc -l)

    # double check the helm chart has gone in
    fi
    if [ $rc -lt $tobuild ]; then echo "only $rc in tf state expected $tobuild .. exit .." && exit; fi

    echo "PASSED $i tests (found $rc resources expected minimum for this stage = $tobuild)"
    cd $cur

done
