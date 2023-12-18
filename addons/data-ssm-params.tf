data "aws_ssm_parameter" "cluster1_vpcid" {
  name        = "/workshop/cluster1_vpcid"
}

data "aws_ssm_parameter" "cluster1_name" {
  name        = "/workshop/cluster1_name"
  
}

data "aws_ssm_parameter" "cluster1_endpoint" {
  name        = "/workshop/cluster1_endpoint"
  
}
data "aws_ssm_parameter" "cluster1_version" {
  name        = "/workshop/cluster1_version" 
}

data "aws_ssm_parameter" "cluster1_oidc_provider_arn" {
  name        = "/workshop/cluster1_oidc_provider_arn" 
}


data "aws_ssm_parameter" "cluster1_certificate_authority_data" {
  name        = "/workshop/cluster1_certificate_authority_data"
}

data "aws_ssm_parameter" "hzid" {
  name        = "/workshop/hzid"
}

  #cluster_name      = module.eks.cluster_name
  #cluster_endpoint  = module.eks.cluster_endpoint
  #cluster_version   = module.eks.cluster_version
  #oidc_provider_arn = module.eks.oidc_provider_arn
