resource "aws_iam_policy" "load-balancer-policy" {
  depends_on=[null_policy.policy]
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS LoadBalancer Controller IAM Policy"

  policy = data.aws_iam_policy_document.example.json
  
}