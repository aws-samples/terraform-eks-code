
ami=`aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.17/amazon-linux-2/recommended/image_id --region eu-west-1 --query "Parameter.Value" --output text`
echo $ami

#cat << EOT > ud.sh
printf "MIME-Version: 1.0\n" > ud.sh
printf "Content-Type: multipart/mixed; boundary=\"==MYBOUNDARY==\"\n" >> ud.sh
printf "\n" >> ud.sh
printf -- "--==MYBOUNDARY==\n" >> ud.sh
printf "Content-Type: text/x-shellscript; charset=\"us-ascii\"\n" >> ud.sh
printf "\n" >> ud.sh
printf "#!/bin/bash\n" >> ud.sh
printf "echo \"Running custom user data script\"\n" >> ud.sh
printf "echo \"Running custom user data script\" > /tmp/me.txt\n" >> ud.sh
printf "yum install -y amazon-ssm-agent\n" >> ud.sh
printf "echo \"yum'd agent\" >> /tmp/me.txt\n" >> ud.sh
printf "systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent\n" >> ud.sh
printf "date >> /tmp/me.txt\n" >> ud.sh
printf "\n" >> ud.sh
printf -- "--==MYBOUNDARY==--" >> ud.sh
#EOT



b64=`cat ud.sh | openssl enc -A -base64`
rm -f mylt2.json manng2.yml
printf "{\n" > mylt2.json
printf "\"LaunchTemplateData\": {\n" >> mylt2.json
printf "\"InstanceType\" : \"t3.small\",\n" >> mylt2.json
printf "\"KeyName\": \"terraform-andyt\",\n" >> mylt2.json
#printf "\"ImageId\": \"%s\",\n" $ami >> mylt.json
printf '\"UserData\": \"%s\"\n' "$b64" >> mylt2.json

printf '\"TagSpecifications\":[\n'  >> mylt2.json
printf '  {\n'  >> mylt2.json
printf '    "ResourceType":"instance",\n'  >> mylt2.json
printf '       "Tags":[\n'  >> mylt2.json
printf '          {\n'  >> mylt2.json
printf '             "Key":"Name",\n'  >> mylt2.json
printf '              "Value":"mycluster1"\n'  >> mylt2.json
printf '          }\n'  >> mylt2.json
printf '        ]\n'  >> mylt2.json
printf '  }\n'  >> mylt2.json
printf ']\n'  >> mylt2.json

printf "}\n" >> mylt2.json
printf "}\n" >> mylt2.json
#cat mylt2.json
echo "delete LT"
st=`aws ec2 delete-launch-template --launch-template-name at-lt-maneksamip2`
echo "create LT"
lt=`aws ec2 create-launch-template \
--launch-template-name at-lt-maneksamip2 \
--cli-input-json file://./mylt2.json`

ltid=`echo $lt | jq .LaunchTemplate.LaunchTemplateId`
echo "create cluster yml"
cat << EOT > manng2.yml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: mycluster1
  region: eu-west-1

managedNodeGroups:
- name: ng-maneksami2
  desiredCapacity: 2
  minSize: 1
  maxSize: 3
  privateNetworking: true 
  launchTemplate:
    id: ${ltid}
  iam:
    withAddonPolicies:
      externalDNS: true
      certManager: true
      ebs: true
      efs: true
      albIngress: true
      autoScaler: true
      cloudWatch: true
EOT










#aws ec2 delete-launch-template --launch-template-name at-lt-eks
