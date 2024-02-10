# validate dns exit of not valid
acc=$(aws sts get-caller-identity --query Account --output text)
dnsl=$(dig $acc.awsandy.people.aws.dev NS +short | wc -l)
if [[ $dnsl -gt 0 ]]; then
    # install cert
    terraform init
    terraforn apply -auto-approve
# prep config
fi
