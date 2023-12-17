echo "circa 45 minutes ..."
rm -f build.log
date >> build.log
cur=`pwd`
cd ~/environment/tfekscode/lb2
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.0/docs/install/iam_policy.json -s
cd $cur
buildok=1
#orig
dirs="tf-setup net iam c9net cicd cluster nodeg lb2 sampleapp extra/nodeg2 extra/eks-cidr2 extra/sampleapp2 extra/fargate extra/fargateapp"
dirs="tf-setup net c9net"

for i in `echo $dirs`;do
    ./build-stage.sh $i 2>&1 | tee -a build.log
    grep Error: build.log
    if [[ $? -eq 0 ]];then
        echo "Error: in build.log"
        exit
    fi
done
date >> build.log

echo "Some post build verifications"
echo "Should have at least 23 pods running in total"
rc=$(kubectl get pods -A | grep Running | wc -l)
if [ $rc -lt 23 ]; then 
echo "ERROR: Found only $rc pods running - expected 23"
else
echo "PASSED: running pod count $rc"
fi

