#!/bin/bash

# Get the private dns
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --region eu-west-2 --output text)
pdns=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=VSCodeServer" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].[PrivateDnsName]' --output text)
iid=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=VSCodeServer" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].[InstanceId]' --output text)
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Construct the ARN
INSTANCE_ARN="arn:aws:ec2:${REGION}:${ACCOUNT_ID}:instance/${iid}"

comm=$(printf "aws cloudfront create-vpc-origin --vpc-origin-endpoint-config '{\"Name\": \"MyEC2VPCOrigin\",\"Arn\": \"${INSTANCE_ARN}\", \"HTTPPort\": 80,\"HTTPSPort\": 443,\"OriginProtocolPolicy\": \"http-only\"}' --output text")
echo $comm
eval $comm

sleep 5

VPC_ORIGIN_ID=$(aws cloudfront list-vpc-origins \
  --query "VpcOriginList.Items[?Name=='MyEC2VPCOrigin'].Id" \
  --output text)

sleep 5
echo "Waiting for the VPC origin to be in deployed state"
ost=$(aws cloudfront get-vpc-origin --id $VPC_ORIGIN_ID --query VpcOrigin.Status --output text)
while [ "$ost" != "Deployed" ]; do
  echo "Waiting for VPC origin to be deployed..."
  sleep 10
  ost=$(aws cloudfront get-vpc-origin --id $VPC_ORIGIN_ID --query VpcOrigin.Status --output text)
done

echo "Creating distribution"
cat > distribution-config.json << EOF
{
  "CallerReference": "cli-vpc-origin-distribution-$(date +%s)",
  "Comment": "vscode distribution with VPC Origin",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "MyVPCOrigin",
        "DomainName": "${pdns}",
        "VpcOriginConfig": {
          "VpcOriginId": "${VPC_ORIGIN_ID}"
        },
        "OriginCustomHeaders": {
          "Quantity": 0
        },
        "ConnectionAttempts": 3,
        "ConnectionTimeout": 10
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "MyVPCOrigin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 7,
      "Items": [
        "GET",
        "HEAD",
        "OPTIONS",
        "PUT",
        "POST",
        "PATCH",
        "DELETE"
      ],
      "CachedMethods": {
        "Quantity": 2,
        "Items": [
          "GET",
          "HEAD"
        ]
      }
    },
    "CachePolicyId": "4135ea2d-6df8-44a3-9df3-4b5a84be39ad",
    "OriginRequestPolicyId": "216adef6-5c7f-47e4-b989-5492eafa07d3",
    "Compress": true,
    "LambdaFunctionAssociations": {
      "Quantity": 0
    },
    "FunctionAssociations": {
      "Quantity": 0
    }
  },
  "Enabled": true,
  "PriceClass": "PriceClass_All"
}
EOF

aws cloudfront create-distribution --distribution-config file://distribution-config.json --output text