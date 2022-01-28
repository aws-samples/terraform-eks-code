resource "kubernetes_namespace" "aws-observability" {

  metadata {
    annotations = {}
    labels = {
      "aws-observability" = "enabled"
    }
    name = "aws-observability"
  }

  timeouts {}
}

resource "kubernetes_config_map" "aws-observability__aws-logging" {
    binary_data = {}
    data        = {
        "output.conf" = <<-EOT
            [OUTPUT]
                Name cloudwatch
                Match *
                region ${data.aws_region.current.name}
                log_group_name fluent-bit-eks-fargate
                log_stream_prefix fargate1-
                auto_create_group true
                sts_endpoint https://sts.eu-west-1.amazonaws.com
                endpoint https://logs.eu-west-1.amazonaws.com  
        EOT
    }

    metadata {
        name             = "aws-logging"
        namespace        = kubernetes_namespace.aws-observability.id
    }
}