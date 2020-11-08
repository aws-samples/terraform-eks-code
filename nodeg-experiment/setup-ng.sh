
#!/bin/bash
# get ami
ami=`aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.17/amazon-linux-2/recommended/image_id --region eu-west-1 --query "Parameter.Value" --output text`
echo $ami
# get cluster ami
api=`aws eks describe-cluster --name mycluster1 | jq .cluster.endpoint | cut -f3 -d'/' | tr -d '"'`
# get CA
ca=`aws eks describe-cluster --name mycluster1 | jq .cluster.certificateAuthority.data | tr -d '"'`

#cat << EOT > ud.sh
printf "MIME-Version: 1.0\n" > ud.sh
printf "Content-Type: multipart/mixed; boundary=\"==MYBOUNDARY==\"\n" >> ud.sh
printf "\n" >> ud.sh
printf -- "--==MYBOUNDARY==\n" >> ud.sh
printf "Content-Type: text/x-shellscript; charset=\"us-ascii\"\n" >> ud.sh
printf "\n" >> ud.sh
printf "#!/bin/bash\n" >> ud.sh
printf "echo \"Running custom user data script\"\n" >> ud.sh
#printf "ls -l /etc/eks >> /tmp/me.txt \n" >> ud.sh
# needs extra args as private ?
# --apiserver-endpoint <cluster-endpoint> --b64-cluster-ca <cluster-certificate-authority>
# needs 4 labels - 
# alpha.eksctl.io/cluster-name
# alpha.eksctl.io/nodegroup-name
# eks.amazonaws.com/nodegroup=
# eks.amazonaws.com/nodegroup-image=

printf "/etc/eks/bootstrap.sh mycluster1 --apiserver-endpoint %s --b64-cluster-ca %s --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup=ng-experiment,eks.amazonaws.com/nodegroup-image=%s'\n" $api $ca $ami >> ud.sh
printf "echo \"Running custom user data script\" > /tmp/me.txt\n" >> ud.sh
printf "yum install -y amazon-ssm-agent\n" >> ud.sh
printf "echo \"yum'd agent\" >> /tmp/me.txt\n" >> ud.sh
printf "systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent\n" >> ud.sh
printf "date >> /tmp/me.txt\n" >> ud.sh
printf "\n" >> ud.sh
printf -- "--==MYBOUNDARY==--" >> ud.sh
#EOT



b64=`cat ud.sh | openssl enc -A -base64`
rm -f mylt.json manng.yml
printf "{\n" > mylt.json
printf "\"LaunchTemplateData\": {\n" >> mylt.json
printf "\"InstanceType\" : \"t3.small\",\n" >> mylt.json
printf "\"KeyName\": \"terraform-andyt\",\n" >> mylt.json
printf "\"ImageId\": \"%s\",\n" $ami >> mylt.json
printf '\"UserData\": \"%s\"\n' "$b64" >> mylt.json
printf "}\n" >> mylt.json
printf "}\n" >> mylt.json
cat mylt.json
echo "delete LT"
st=`aws ec2 delete-launch-template --launch-template-name at-lt-mycluster1`
echo "create LT"
lt=`aws ec2 create-launch-template \
--launch-template-name at-lt-mycluster1 \
--cli-input-json file://./mylt.json`

ltid=`echo $lt | jq .LaunchTemplate.LaunchTemplateId`
echo "create nodegroup yml"


cat << EOT > manng-nodegroup.yml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: mycluster1
  region: eu-west-1

managedNodeGroups:
- name: ng-experiment
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
