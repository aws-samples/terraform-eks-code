echo "circa 45 minutes ..."
rm -f build.log
date >> build.log
cur=`pwd`
cd ~/environment/tfekscode/lb2
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json -s
cd $cur
buildok=1
dirs="tf-setup net iam c9net cluster nodeg lb2 cicd extra/nodeg2 extra/eks-cidr2 extra/sampleapp2 extra/.fargate extra/.karpenter"
for i in `echo $dirs`;do
    ./build-stage.sh $i 2>&1 | tee -a build.log
    grep Error: build.log
    if [[ $? -eq 0 ]];then
        echo "Error: in build.log"
        exit
    fi
done
date >> build.log

