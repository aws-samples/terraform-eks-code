# get the private dns
aws cloudfront create-distribution \
  --distribution-config '{
    "CallerReference": "'$(date +%s)'",
    "DefaultRootObject": "",
    "Origins": {
      "Quantity": 1,
      "Items": [{
        "Id": "vscode-vpc-origin",
        "DomainName": "ip-172-31-64-56.eu-west-2.compute.internal",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          },
          "OriginReadTimeout": 30,
          "OriginKeepaliveTimeout": 5
        }
      }]
    },
    "DefaultCacheBehavior": {
      "TargetOriginId": "vscode-vpc-origin",
      "ViewerProtocolPolicy": "redirect-to-https",
      "AllowedMethods": {
        "Quantity": 7,
        "Items": ["HEAD","DELETE","POST","GET","OPTIONS","PUT","PATCH"],
        "CachedMethods": {
          "Quantity": 2,
          "Items": ["GET", "HEAD"]
        }
      },
      "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
      "TrustedSigners": {
        "Enabled": false,
        "Quantity": 0
      }
    },
    "Comment": "Distribution for VSCode",
    "Enabled": true
  }'


  echo "url/?folder=/home/ec2-user/environment"