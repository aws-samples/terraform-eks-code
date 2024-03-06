data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "kubernetes_deployment" "game-2048__deployment-2048" {

  metadata {
    name      = "deployment-2048"
    namespace = "game-2048"
  }

  spec {
    replicas = 4
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "app-2048"
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
        labels      = { "app.kubernetes.io/name" = "app-2048" }
      }

      spec {

        restart_policy                   = "Always"
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          image             = format("%s.dkr.ecr.%s.amazonaws.com/aws/awsandy/docker-2048", data.aws_caller_identity.current.account_id, data.aws_region.current.name)
          #image             = format("%s.dkr.ecr.%s.amazonaws.com/sample-app", data.aws_caller_identity.current.account_id, data.aws_region.current.name)

          #$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/sample-app
          image_pull_policy = "Always"
          name              = "app-2048"
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


