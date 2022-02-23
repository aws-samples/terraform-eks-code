kubectl describe deployment  deployment-2048 -n game-2048

kubectl describe pods deployment-2048-67c7bd54d5-d969k -n game-2048

kubectl rollout restart deployment deployment-2048 -n game-2048


kubectl get events -n deployment-2048

### Trouble shooting list form support:

—> I checked the VPC network configuration and couldn’t locate the issue.

—> Then I checked the Fargate profile “fargate1” in EKS cluster “mycluster1” and it seems fine to me.

—> I also checked the IAM role assigned to the fargate profile and it also have the right permissions.

—> Then I checked the Security Groups on EKS cluster and can see that the EKS cluster security group is “sg-084a7cc6270d4795a” and additional security group is “sg-0e5f98d3c6ddca342”.

—> As we are using the VPC endpoints in EKS so I checked the VPC endpoint configuration.

—> While checking the VPC endpoints I can see that you have added this Security Group “sg-068192a2bb8b64634” on VPC endpoints.

—> The Security Group Allowing the traffic from “sg-068192a2bb8b64634” and “sg-0e5f98d3c6ddca342” Security groups and this might be causing the issue. 

### Explanation :

You might already aware of that the EKS fargate pod only have the Cluster security group “sg-084a7cc6270d4795a” attached by default. As we are using the VPC endpoints and not allowing the traffic from the Cluster security group “sg-084a7cc6270d4795a” hence Pod are unable to run successfully.

For fargate the cluster SG must be on sts, dkr* & logs as a minimum


For fargate logging:

kind: ConfigMap
apiVersion: v1
metadata:
  name: aws-logging
  namespace: aws-observability
data:
  output.conf: |
    [OUTPUT]
        Name cloudwatch
        Match *
        region eu-west-1
        log_group_name fluent-bit-cloudwatch
        log_stream_prefix from-fluent-bit-1-
        auto_create_group true
        sts_endpoint https://sts.eu-west-1.amazonaws.com 
        endpoint https://logs.eu-west-1.amazonaws.com 


Note the log group is only created when:

* The CW permissions are added to the fargate profile
* the pod is running
* the container produces soem output




                Name cloudwatch
                Match *
                region ${data.aws_region.current.name}
                log_group_name fluent-bit-cloudwatch1
                log_stream_prefix from-fluent-bit-1-
                auto_create_group true
                sts_endpoint https://sts.eu-west-1.amazonaws.com
                endpoint https://logs.eu-west-1.amazonaws.com
