echo "circa 45 minutes ..."

rm -f build.log
date >> build.log
buildok=1
#orig
dirs="tf-setup net cluster nodepool addons"
#set -e # turn on error checking - exit if error
for i in `echo $dirs`;do
    ./build-stage.sh $i 2>&1 | tee -a build.log
    grep Error: build.log
    if [[ $? -eq 0 ]];then
        echo "Error: in build.log"
        exit
    fi
done
date >> build.log

set +e # turn off error checking - proceed if error
echo "Some post build verifications"
echo "Should have at least 21 pods running in total"
rc=$(kubectl get pods -A | grep Running | wc -l)
if [ $rc -lt 21 ]; then 
echo "ERROR: Found only $rc pods running - expected 21"
else
echo "PASSED: running pod count $rc"
