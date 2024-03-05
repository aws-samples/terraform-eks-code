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
      cidr_blocks = [element(local.secondary_cidr_blocks, 0)]
    }
    egress_https = {
      type="egress"
      description = "HTTPS out of VPC"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  endpoints = merge({
    # ECR images are stored on S3
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = {
        Name = "${local.name}-s3"
      }
    }
    },
    { for service in toset(["autoscaling", "ecr.api", "ecr.dkr", "ec2", "guardduty-data", "ec2messages", "sts", "logs", "ssm", "ssmmessages", "codecommit", "git-codecommit", "codebuild", "codepipeline", "codedeploy"]) :
      replace(service, ".", "_") =>
      {
        service             = service
        subnet_ids          = module.vpc.private_subnets
        private_dns_enabled = true
        tags                = { Name = "${local.name}-${service}" }
      }
  })
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

