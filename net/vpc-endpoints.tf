module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name_prefix = "${local.name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https1 = {
      description = "HTTPS from VPC 1"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
    ingress_https2 = {
      description = "HTTPS from VPC 2"
      cidr_blocks = [module.vpc.aws_vpc_ipv4_cidr_block_association]
    }
  }

  endpoints = {
    
    ssm = {
      service             = "ssm"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ec2messages = {
      service             = "ec2messages"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ec2 = {
      service             = "ec2"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
    },
    logs = {
      service             = "logs"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
    },
    xray = {
      service             = "xray"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    elasticloadbalancing = {
      service             = "elasticloadbalancing"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ecr_api = {
      service             = "ecr.api"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
    },
    autoscaling = {
      service             = "autoscaling"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }
    sts = {
      service             = "sts"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }
    kms = {
      service             = "kms"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    secretsmanager = {
      service             = "secretsmanager"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ssmmessages = {
      service             = "ssmmessages"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = {
        Name = "${local.name}-s3-vpc-endpoint"
      }
    },
    eks = {
      service             = "eks"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    efs = {
      service             = "elasticfilesystem"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    grafana = {
      service             = "grafana"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    cloudwatch = {
      service             = "monitoring"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    cloudwatch_logs = {
      service             = "logs"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    cloudwatch_events = {
      service             = "events"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    codebuild = {
      service             = "codebuild"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    codecommit = {
      service             = "codecommit"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    codedeploy = {
      service             = "codedeploy"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    codepipeline = {
      service             = "codepipeline"
      #private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = merge(local.tags, {
        Project  = "Secret"
        Endpoint = "true"
      })
    }


  }
}



################################################################################
# Supporting Resources
################################################################################


data "aws_iam_policy_document" "generic_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpc"

      values = [module.vpc.vpc_id]
    }
  }
}

