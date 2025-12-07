#for i in $(ls *.yaml); do
#    sn=$(echo $i | cut -f1 -d'.')
#    echo $sn
#    aws cloudformation delete-stack --stack-name $sn
#done
aws cloudformation delete-stack --stack-name vscode --region eu-west-1
