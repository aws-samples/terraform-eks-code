vpcid=$(aws ssm get-parameter --name /workshop/tf-eks/eks-vpc --query Parameter.Value --output text)
aws route53 create-hosted-zone --name rabbit.local \
--caller-reference my-private-zone\
--hosted-zone-config Comment=”my private zone”,PrivateZone=true \
--vpc VPCRegion=eu-west-1,VPCId=$vpcid
aws route53 create-hosted-zone --name hamster.local \
--caller-reference my-private-zone\
--hosted-zone-config Comment=”my private zone”,PrivateZone=true \
--vpc VPCRegion=eu-west-1,VPCId=$vpcid
aws route53 create-hosted-zone --name chipmunk.local \
--caller-reference my-private-zone\
--hosted-zone-config Comment=”my private zone”,PrivateZone=true \
--vpc VPCRegion=eu-west-1,VPCId=$vpcid
