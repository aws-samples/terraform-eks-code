## OIDC Provider
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.mycluster1.identity.0.oidc.0.issuer
}
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list = ["sts.amazonaws.com"]
#  thumbprint_list = concat([data.tls_certificate.cluster.certificates.0.sha1_fingerprint], var.oidc_thumbprint_list)
  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
  url = aws_eks_cluster.mycluster1.identity.0.oidc.0.issuer
}


### Enabling IAM Roles for Service Accounts
data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cluster" {
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role_policy.json
  name               = "cluster"
}
