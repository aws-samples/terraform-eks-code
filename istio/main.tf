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

locals {
  istio_chart_url     = "https://istio-release.storage.googleapis.com/charts"
  istio_chart_version = "1.20.2"

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

  
 
    helm_releases = {
        istio-base = {
        chart         = "base"
        chart_version = local.istio_chart_version
        repository    = local.istio_chart_url
        name          = "istio-base"
        namespace     = kubernetes_namespace_v1.istio_system.metadata[0].name
        }

        istiod = {
        chart         = "istiod"
        chart_version = local.istio_chart_version
        repository    = local.istio_chart_url
        name          = "istiod"
        namespace     = kubernetes_namespace_v1.istio_system.metadata[0].name

        set = [
            {
            name  = "meshConfig.accessLogFile"
            value = "/dev/stdout"
            }
        ]
        }

        istio-ingress = {
        chart            = "gateway"
        chart_version    = local.istio_chart_version
        repository       = local.istio_chart_url
        name             = "istio-ingress"
        namespace        = "istio-ingress" # per https://github.com/istio/istio/blob/master/manifests/charts/gateways/istio-ingress/values.yaml#L2
        create_namespace = true

        set = [
            {
            name  = "resources.requests.cpu"
            value = "110m"
            },
            {
            name  = "service.ports[0].name"
            value = "status-port"
            },
            {
            name  = "service.ports[0].port"
            value = "15021"
            },
            {
            name  = "service.ports[0].protocol"
            value = "TCP"
            },
            {
            name  = "service.ports[0].targetPort"
            value = "15021"
            },
            {
            name  = "service.ports[1].name"
            value = "http2"
            },
            {
            name  = "service.ports[1].port"
            value = "80"
            },
            {
            name  = "service.ports[1].protocol"
            value = "TCP"
            },
            {
            name  = "service.ports[1].targetPort"
            value = "8080"
            },
            {            
            name  = "service.ports[2].name"
            value = "https"
            },
            {
            name  = "service.ports[2].port"
            value = "443"
            },
            {
            name  = "service.ports[2].protocol"
            value = "TCP"
            },
            {
            name  = "service.ports[2].targetPort"
            value = "443"
            }
        ]


        values = [
            yamlencode(
            {
                labels = {
                istio = "ingressgateway"
                }
                service = {
                annotations = {
                    "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
                    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
                    "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
                    "service.beta.kubernetes.io/aws-load-balancer-attributes"      = "load_balancing.cross_zone.enabled=true"
                }
                }
            }
            )
        ]
        }
    }


  tags = {
    Environment = "dev"
  }
}


resource "kubernetes_namespace_v1" "istio_system" {
  metadata {
    name = "istio-system"
  }
}