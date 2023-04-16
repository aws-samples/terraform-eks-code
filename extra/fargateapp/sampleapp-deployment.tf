

resource "kubernetes_deployment" "fargate1__logging_server" {

  metadata {
    name      = "logging-server"
    namespace = kubernetes_namespace.fargate1.id
  }

  timeouts {   
    create = "3m"
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "logging-server"
      }
    }
    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        annotations = {}
        labels      = { "app.kubernetes.io/name" = "logging-server" }
      }

      spec {
        container {
          image             = format("%s.dkr.ecr.%s.amazonaws.com/aws/nginx/nginx", data.aws_caller_identity.current.account_id, data.aws_region.current.name)
          image_pull_policy = "Always"
          name              = "nginx"
          port {
            container_port = 80
            protocol       = "TCP"
          }

          resources {
          }
        }
      }
    }
  }


}


