data "external" "find_cluster" {
  program = ["bash", "findCluster.sh"]
}

output "Name" {
  value = data.external.find_cluster.result.Name
}


data "aws_eks_cluster" "example" {
  name = data.external.find_cluster.result.Name
}

