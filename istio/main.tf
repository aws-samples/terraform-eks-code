# istio via Terraform

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
  istio_charts_url = "https://istio-release.storage.googleapis.com/charts"
}

variable "istio-namespace" {
  description = "The name of the istio namespace"
  type        = string
  default     = "istio-system"
}



resource "helm_release" "istio-base" {
  repository       = local.istio_charts_url
  chart            = "base"
  name             = "istio-base"
  namespace        = var.istio-namespace
  version          = "1.20.3"
  create_namespace = true
}


resource "helm_release" "istiod" {
  repository       = local.istio_charts_url
  chart            = "istiod"
  name             = "istiod"
  namespace        = var.istio-namespace
  create_namespace = true
  version          = "1.20.3"
  depends_on       = [helm_release.istio-base]
}

resource "kubernetes_namespace_v1" "istio-ingress" {
  metadata {
    labels = {
      istio-injection = "enabled"
    }

    name = "istio-ingress"
  }
}

resource "helm_release" "istio-ingress" {
  repository = local.istio_charts_url
  chart      = "gateway"
  #name       = "istio-ingress"
  name       = "istio-ingressgateway"   # to match selector in sample app
  #name       = "ingressgateway"   # to match selector in sample app
  namespace  = kubernetes_namespace_v1.istio-ingress.id
  version    = "1.20.3"
  depends_on = [helm_release.istiod]
  # need to listen on  port to 8080 ?????
  #"gateways.istio-ingressgateway.ports[1].targetPort=80"
  #set {
  #  name = "service.ports[1].targetPort"
  #  value = "8080"
  #}
}