if [[ $1 != "" ]];then
    cd ~/environment/tfekscode/$1
fi 
for i in `terraform state list | grep -v '^data.'`; do
terraform state rm $i
done