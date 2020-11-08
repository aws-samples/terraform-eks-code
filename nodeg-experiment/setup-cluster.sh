
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
#printf "ls -l /etc/eks >> /tmp/me.txt \n" >> ud.sh
# needs extra args as private ?
# --apiserver-endpoint <cluster-endpoint> --b64-cluster-ca <cluster-certificate-authority>
printf "/etc/eks/bootstrap.sh mycluster1 --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup=ng-mycluster1,eks.amazonaws.com/nodegroup-image=%s'\n" $ami >> ud.sh
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
echo "create cluster yml"
cat << EOT > manng-cluster.yml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: mycluster1
  region: eu-west-1


cloudWatch:
    clusterLogging:
        # enable specific types of cluster control plane logs
        enableTypes: ["all"]
        # all supported types: "api", "audit", "authenticator", "controllerManager", "scheduler"
        # supported special values: "*" and "all"
privateCluster:
  enabled: true
  additionalEndpointServices:
  # For Cluster Autoscaler
  - "autoscaling"
  # CloudWatch logging
  - "logs"


EOT


cat << EOT > manng-nodegroup.yml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: mycluster1
  region: eu-west-1

managedNodeGroups:
- name: ng-mycluster1
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
