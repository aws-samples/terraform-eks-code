for i in $(ls *.yaml); do
    sn=$(echo $i | cut -f1 -d'.')
    echo $sn
    aws cloudformation create-stack --stack-name $sn --template-body file://$i --capabilities CAPABILITY_NAMED_IAM
done
