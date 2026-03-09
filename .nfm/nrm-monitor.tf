resource "aws_networkflowmonitor_monitor" "example" {
  monitor_name = "eks-cluster-name-monitor"
  scope_arn    = aws_networkflowmonitor_scope.example.scope_arn

  local_resource {
    type       = "AWS::EKS::Cluster"
    identifier = data.aws_eks_cluster.eksworkshop.arn
  }

  remote_resource {
    type       = "AWS::Region"
    identifier = data.aws_region.current.region # this must be the same region that the cluster is in
  }

  tags = {
    Name = "example"
  }
}