st=()
st+=$(terraform state list)

for i in ${st[@]}; do
echo $i
terraform state rm $i
done
