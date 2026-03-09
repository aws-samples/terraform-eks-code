# Kubernetes Provider Configuration
# Access to the EKS cluster for Terraform operations
# Uses AWS CLI for authentication via IRSA# Kubernetes Provider Configuration
# Configures access to the EKS cluster for Terraform operations
# Uses AWS CLI for authentication via IRSA

provider "kubernetes" {
  # Cluster API endpoint from SSM parameter
  host                   = data.aws_ssm_parameter.endpoint.value
  
  # Cluster CA certificate (base64 decoded)
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
  
  # Local kubeconfig file (fallback)
  
  # AWS CLI exec authentication
  # Uses AWS IAM for authentication with short-lived tokens (15 min)
  # Automatically refreshed by AWS CLI
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # Requires AWS CLI installed locally where Terraform runs
    args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
  }
}

# Helm Provider Configuration
# Manages Helm chart installations (External DNS, External Secrets, etc.)
provider "helm" {
  kubernetes {
    host                   = data.aws_ssm_parameter.endpoint.value
    cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)

    # Same exec authentication as Kubernetes provider
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
    }
  }
}

# kubectl Provider Configuration
# Used to apply raw Kubernetes manifests
provider "kubectl" {
  # Retry failed operations up to 5 times
  # Handles transient API server issues
  apply_retry_count      = 5
  
  host                   = data.aws_ssm_parameter.endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
  
  # Don't load local kubeconfig (use exec auth only)
  load_config_file       = false

  # Same exec authentication as other providers
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
  }
}

# EKS Blueprints Add-ons Module
# Installs and configures essential Kubernetes add-ons
# Handles IRSA role creation, Helm chart installation, and configuration

# Note: EKS Auto Mode handles load balancing automatically
# So we only install: External DNS, External Secrets, and CloudWatch Metrics

module "eks_blueprints_addons" {
  
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.21.0" # Ensure to update this to the latest/desired version

  # Optional: AWS managed EKS add-ons
  # Commented out - using separate aws_eks_addon resources instead
  #eks_addons = { 
  #  amazon-cloudwatch-observability = {
  #      most_recent = true
  #    }
  #}

  # Required: Cluster information from SSM parameters
  cluster_name      = data.aws_ssm_parameter.cluster-name.value
  cluster_endpoint  = data.aws_ssm_parameter.endpoint.value
  cluster_version   = data.aws_ssm_parameter.tf-eks-version.value
  oidc_provider_arn = data.aws_ssm_parameter.oidc_provider_arn.value

  # External DNS Configuration
  # Automatically creates/updates Route53 DNS records for Services and Ingresses
  enable_external_dns = true
  external_dns = {
    name             = "external-dns"
    namespace        = "external-dns"
    service_account  = "external-dns"
    create_namespace = true
    # Wait for load balancer controller to be ready
    depends_on       = [null_resource.sleep]
  }
  # Route53 zone ARN for IRSA permissions
  external_dns_route53_zone_arns = [data.aws_route53_zone.phz.arn]
 
  # External Secrets Configuration
  # Syncs secrets from AWS Secrets Manager/Parameter Store to Kubernetes
  # Note: enable_external_secrets is commented out - using explicit config instead
  external_secrets = {
    name             = "external-secrets"
    chart_version    = "0.14.2"
    repository       = "https://charts.external-secrets.io"
    namespace        = "external-secrets"
    create_namespace = true
  }

  # CloudWatch Metrics - done in cluster build
  # Commented out - using separate aws_eks_addon resource
  #enable_aws_cloudwatch_metrics = true

  # Cert Manager - disabled (can be enabled in observability stage)
  # Manages TLS certificates from Let's Encrypt or AWS Private CA
  enable_cert_manager = false
  #cert_manager_route53_hosted_zone_arns = [format("arn:aws:route53:::hostedzone/%s",data.aws_ssm_parameter.hzid.value)] 

  #cert_manager = {
  #    depends_on = [module.eks_blueprints_addons.aws_load_balancer_controller]
  #    namespace="cert-manager"
  #    create_namespace = true
  #    set = [
  #    {
  #      name  = "webhook.securePort"
  #      value = 10260  # For Fargate compatibility
  #    },
  #    ]
  #  }

  # AWS Private CA Issuer - disabled
  # Issues certificates from AWS Private Certificate Authority
  enable_aws_privateca_issuer = false
  aws_privateca_issuer = {
    #acmca_arn        = aws_acmpca_certificate_authority.this.arn
    namespace        = "aws-privateca-issuer"
    create_namespace = true
  }

  # Fargate Fluent Bit - commented out
  # Log collection for Fargate pods
  #fargate_fluentbit = {
  #  flb_log_cw = true
  #  namespace=kubernetes_namespace_v1.fluentbit-fargate.id # default is aws_observability
  #}

  #fargate_fluentbit_cw_log_group = {
  #  create          = true
  #  use_name_prefix = true
  #  name_prefix     = format("eks-%s-fargate-",data.aws_ssm_parameter.cluster1_name.value)
  #  retention_in_days = 7
  #  skip_destroy    = false
  #}

  # AWS for Fluent Bit - commented out
  # Log collection for EC2 nodes (replaced by CloudWatch Observability add-on)
  #enable_aws_for_fluentbit = true
  #aws_for_fluentbit = {
  #  namespace=kubernetes_namespace_v1.fluentbit-nodes.id
  #  enable_containerinsights = true
  #  set = [{
  #      name  = "cloudWatchLogs.autoCreateGroup"
  #      value = true
  #    }
  #       value = data.aws_ssm_parameter.eks-vpc.value
  #    },
  #  ]
  #}

  # Tags applied to all resources created by this module
  tags = {
    Environment = "dev"
  }

  # CloudWatch Metrics Configuration
  # Collects cluster and pod metrics, sends to CloudWatch
  aws_cloudwatch_metrics = {
    namespace        = "cw-metrics"
    create_namespace = true
  }

  # AWS Load Balancer Controller - commented out
  # Auto Mode handles load balancing automatically
  # Uncomment if not using Auto Mode
  #aws_load_balancer_controller = {
  #  namespace="kube-system"
  #  set = [
  #    {
  #      name  = "vpcId"
  #    },
  #  ]
  #}

  #aws_for_fluentbit_cw_log_group = {
  #  create          = true
  #  use_name_prefix = true
  #  name_prefix     = "eks-cluster1-"
  #  retention       = 7
  #  skip_destroy    = false
  #}
}