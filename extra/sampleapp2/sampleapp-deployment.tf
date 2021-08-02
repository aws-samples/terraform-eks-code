resource "kubernetes_deployment" "game1-2048__deployment1-2048" {

  metadata {
    name      = "deployment1-2048"
    namespace = "game1-2048"
  }

  spec {
    replicas = 4
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "app1-2048"
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
        labels      = { "app.kubernetes.io/name" = "app1-2048" }
      }

      spec {

        node_selector                    = { "eks/nodegroup-name" = "ng1-mycluster1" }
        restart_policy                   = "Always"
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          image             = format("%s.dkr.ecr.%s.amazonaws.com/sample-app", data.aws_caller_identity.current.account_id, data.aws_region.current.name)
          image_pull_policy = "Always"
          name              = "app1-2048"
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

resource "kubernetes_deployment" "game2-2048__deployment2-2048" {

  metadata {
    name      = "deployment2-2048"
    namespace = "game2-2048"
  }

  spec {
    replicas = 4
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "app2-2048"
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
        labels      = { "app.kubernetes.io/name" = "app2-2048" }
      }

      spec {

        node_selector                    = { "eks/nodegroup-name" = "ng2-mycluster1" }
        restart_policy                   = "Always"
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          image             = format("%s.dkr.ecr.%s.amazonaws.com/sample-app", data.aws_caller_identity.current.account_id, data.aws_region.current.name)
          image_pull_policy = "Always"
          name              = "app2-2048"
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

