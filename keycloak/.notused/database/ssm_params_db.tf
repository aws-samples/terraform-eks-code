resource "aws_ssm_parameter" "db_hostname" {
  name        = "/workshop/tf-eks/db_hostname"
  description = "mysql db hostname"
  type        = "String"
  value = module.aurora_mysql.cluster_endpoint
  tags = {
    workshop = "tf-eks-workshop"
  }
}