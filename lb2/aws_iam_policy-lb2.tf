resource "aws_iam_policy" "load-balancer-policy" {
  depends_on  = [null_resource.policy]
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS LoadBalancer Controller IAM Policy"

  policy = file("iam-policy.json")
  
}