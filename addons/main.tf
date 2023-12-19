

provider "kubernetes" {
  host                   = data.aws_ssm_parameter.endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
  config_path = "~/.kube/config"
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_ssm_parameter.endpoint.value
    cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = data.aws_ssm_parameter.endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
  }
}



module "eks_blueprints_addons" {
  
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.11" #ensure to update this to the latest/desired version

  #eks_addons = { 
  #  amazon-cloudwatch-observability = {
  #      most_recent = true
  #    }
  #}

  cluster_name      = data.aws_ssm_parameter.cluster-name.value
  cluster_endpoint  = data.aws_ssm_parameter.endpoint.value
  cluster_version   = data.aws_ssm_parameter.tf-eks-version.value
  oidc_provider_arn = data.aws_ssm_parameter.oidc_provider_arn.value

  enable_aws_load_balancer_controller     = true
 
  enable_fargate_fluentbit                = false # get logs for fargate pods
  #enable_cluster_proportional_autoscaler = true
  #enable_karpenter                       = true
  #enable_kube_prometheus_stack           = true
  enable_metrics_server                   = true
  enable_aws_cloudwatch_metrics           = true # container insights

  enable_cert_manager                     = false   #turned on in observability accel)
  #cert_manager_route53_hosted_zone_arns  = [format("arn:aws:route53:::hostedzone/%s",data.aws_ssm_parameter.hzid.value)] 

  #cert_manager = {
  #    depends_on = [module.eks_blueprints_addons.aws_load_balancer_controller]
  #    namespace="cert-manager"
  #    create_namespace = true
  #    set = [
  #    {
  #      name  = "webhook.securePort"
  #      value = 10260                  # for fargatre
  #    },
  #    ]
  #  }

  enable_external_dns                    = true
  external_dns = {

    name          = "external-dns"
    namespace     = "external-dns"
    create_namespace = true
    depends_on = [null_resource.sleep]
  }
  #external_dns_route53_zone_arns = [data.aws_route53_zone.keycloak.arn]


  enable_aws_privateca_issuer             = false
  aws_privateca_issuer = {
    #acmca_arn        = aws_acmpca_certificate_authority.this.arn
    namespace        = "aws-privateca-issuer"
    create_namespace = true
  }

 

  #fargate_fluentbit = {
  #  flb_log_cw = true
    #namespace=kubernetes_namespace_v1.fluentbit-fargate.id # default is aws_observability
  #}

  #fargate_fluentbit_cw_log_group = {  #/eks-cluster1/fargate20231031163741692800000002
  #  create          = true
  #  use_name_prefix = true # Set this to true to enable name prefi
  #  name_prefix       = format("eks-%s-fargate-",data.aws_ssm_parameter.cluster1_name.value)
  #  name = format("/%s/fargate",data.aws_ssm_parameter.cluster1_name.value)
  #  retention_in_days = 7
  #  #kms_key_id        = "arn:aws:kms:us-west-2:xxxx:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  #  skip_destroy      = false
  #}

  #enable_aws_for_fluentbit                = true # get logs out to CW   - done in observability accelerator
  #aws_for_fluentbit = {
  #  namespace=kubernetes_namespace_v1.fluentbit-nodes.id
  #  enable_containerinsights = true
  #  set = [{
  #      name  = "cloudWatchLogs.autoCreateGroup"
  #      value = true
  #    }
  #  ]
  #}

  #aws_for_fluentbit_cw_log_group = {  # creates log group "/aws/eks/c1-lattice/aws-fluentbit-logs"
  #  create          = true
  #  use_name_prefix = true # Set this to true to enable name prefix
  #  name_prefix     = "eks-cluster1-"
  #  retention       = 7
  #  skip_destroy      = false
  #}


  aws_cloudwatch_metrics = {
    namespace="cw-metrics"
    create_namespace = true
  }

  metrics_server = {
    namespace="metrics"
    create_namespace = true
  }

  aws_load_balancer_controller = {
    #namespace=kubernetes_namespace_v1.aws_load_balancer_controller.id
    namespace="aws-lb-controller"
    create_namespace = true
    set = [
      {
        name  = "vpcId"
        value = data.aws_ssm_parameter.eks-vpc.value
      },
    ]
  }

  #enable_external_secrets = true    # do in addons

  #external_secrets = {
  #  name          = "external-secrets"
  #  chart_version = "0.9.9"
  #  repository    = "https://charts.external-secrets.io"
  #  namespace     = "external-secrets"
  #  create_namespace = true
  #}



  tags = {
    Environment = "dev"
  }
}