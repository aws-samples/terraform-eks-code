resource "aws_iam_policy" "appmesh-policy" {
  depends_on  = [null_resource.policy]
  name        = "AWSAppMeshK8sControllerIAMPolicy"
  path        = "/"
  description = "AWS AppMesh Controller IAM Policy"

  policy = file("iam-policy.json")
  
}