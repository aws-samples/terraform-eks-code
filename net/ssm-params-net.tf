# SSM Parameter Store - Network Configuration
# Stores network infrastructure outputs for use by downstream stages
# These parameters are read by cluster, nodepool, and addons stages

# CI/CD VPC ID (currently same as EKS VPC)
# Reserved for future CI/CD pipeline integration
resource "aws_ssm_parameter" "cicd-vpc" {
  name        = "/workshop/tf-eks/cicd-vpc"
  description = "The cicd vpc id"
  type        = "String"
  value = module.vpc.vpc_id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

# EKS VPC ID
# Primary VPC where EKS cluster and worker nodes are deployed
resource "aws_ssm_parameter" "eks-vpc" {
  name        = "/workshop/tf-eks/eks-vpc"
  description = "The eks vpc id"
  type        = "String"
  value = module.vpc.vpc_id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

# EKS VPC CIDR block
# Used for security group rules and network planning
resource "aws_ssm_parameter" "eks-cidr" {
  name        = "/workshop/tf-eks/eks-cidr"
  description = "The EKS cluster main CIDR"
  type        = "String"
  value = module.vpc.vpc_cidr_block
  tags = {
    workshop = "tf-eks-workshop"
  }
}

# CI/CD VPC CIDR block (currently same as EKS CIDR)
# Reserved for future CI/CD pipeline integration
resource "aws_ssm_parameter" "cicd-cidr" {
  name        = "/workshop/tf-eks/cicd-cidr"
  description = "The cicd cidr block"
  type        = "String"
  value = module.vpc.vpc_cidr_block
  tags = {
    workshop = "tf-eks-workshop"
  }
}

# Private subnet IDs (JSON-encoded array)
# Subnets where EKS worker nodes are deployed
# Usage: jsondecode(data.aws_ssm_parameter.private_subnets.value)
resource "aws_ssm_parameter" "private_subnets" {
  name        = "/workshop/tf-eks/private_subnets"
  description = "The private subnets for cluster"
  type        = "StringList"
  value = jsonencode(module.vpc.private_subnets)
  tags = {
    workshop = "tf-eks-workshop"
  }
}  

# Intra subnet IDs (JSON-encoded array)
# Isolated subnets for EKS control plane ENIs and VPC endpoints
# No internet access - reduces costs and improves security
resource "aws_ssm_parameter" "intra_subnets" {
  name        = "/workshop/tf-eks/intra_subnets"
  description = "The intra subnets for cluster"
  type        = "StringList"
  value = jsonencode(module.vpc.intra_subnets)
  tags = {
    workshop = "tf-eks-workshop"
  }
}  

# Database subnets - currently not used
# Uncomment if RDS or other database services are added to the workshop
#resource "aws_ssm_parameter" "database_subnets" {
#  name        = "/workshop/tf-eks/database_subnets"
#  description = "The intra subnets for cluster"
#  type        = "StringList"
#  value = jsonencode(module.vpc.database_subnets)
#  tags = {
#    workshop = "tf-eks-workshop"
#  }
#} 

# Database subnet group name - currently not used
# Uncomment if RDS or other database services are added to the workshop
#resource "aws_ssm_parameter" "database_subnet_group_name" {
#  name        = "/workshop/tf-eks/database_subnet_group_name"
#  description = "Database subnet group name"
#  type        = "String"
#  value = module.vpc.database_subnet_group_name
#  tags = {
#    workshop = "tf-eks-workshop"
#  }
#}

# Private route table ID
# Route table for private subnets (worker nodes)
# Used to add routes for VPC peering and other connectivity
resource "aws_ssm_parameter" "private_rtb" {
  name        = "/workshop/tf-eks/private_rtb"
  description = "The private route table id for cluster"
  type        = "String"
  value = element(module.vpc.private_route_table_ids,0)
  tags = {
    workshop = "tf-eks-workshop"
  }
} 

# Intra route table ID
# Route table for intra subnets (control plane ENIs)
# Used to add routes for VPC peering
resource "aws_ssm_parameter" "intra_rtb" {
  name        = "/workshop/tf-eks/intra_rtb"
  description = "The intra route table id for cluster"
  type        = "String"
  value = element(module.vpc.intra_route_table_ids,0)
  tags = {
    workshop = "tf-eks-workshop"
  }
} 

# Public route table ID
# Route table for public subnets (NAT Gateway, load balancers)
# Reserved for future use
resource "aws_ssm_parameter" "public_rtb" {
  name        = "/workshop/tf-eks/public_rtb"
  description = "The public route table id for cluster"
  type        = "String"
  value = element(module.vpc.public_route_table_ids,0)
  tags = {
    workshop = "tf-eks-workshop"
  }
} 

# Private hosted zone ID
# Route53 zone for internal DNS resolution
# Used for Keycloak and other internal services
resource "aws_ssm_parameter" "phz-id" {
  name        = "/workshop/tf-eks/phz-id"
  description = "The id for private hosted zone"
  type        = "String"
  value = aws_route53_zone.keycloak.id
  tags = {
    workshop = "tf-eks-workshop"
  }
} 
