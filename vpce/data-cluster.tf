data "external" "find_cluster" {
  program = ["bash", "findCluster.sh"]
}

output "Name" {
  value = data.external.find_cluster.result.Name
}


data "aws_eks_cluster" "cluster" {
  name = data.external.find_cluster.result.Name
}

output "eksvpcid" {
  value = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
}



