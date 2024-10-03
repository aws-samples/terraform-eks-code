echo "circa 45 minutes ..."
rm -f build.log
date >> build.log
buildok=1
#orig
dirs="tf-setup net c9net cluster"
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
