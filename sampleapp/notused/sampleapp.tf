resource "kubernetes_namespace" "game-2048" {
  metadata {
    name = "game-2048"
  }

  timeouts {   
    delete = "20m"
  }
}


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

        node_selector                    = { "alpha.eksctl.io/nodegroup-name" = "ng1-mycluster1" }
        restart_policy                   = "Always"
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          image             = format("%s.dkr.ecr.%s.amazonaws.com/sample-app", data.aws_caller_identity.current.account_id, data.aws_region.current.name)
          image_pull_policy = "Always"
          name              = "app-2048"
          port {
            container_port = 80
            host_port      = 0
            protocol       = "TCP"
          }

          resources {
          }
        }
      }
    }
  }


}


resource "kubernetes_service" "game-2048__service-2048" {

  metadata {
    name      = "service-2048"
    namespace = "game-2048"
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "app-2048"
    }

    type = "NodePort"

    port {
      port        = 80
      protocol    = "TCP"
      target_port = "80"
    }
  }

}

