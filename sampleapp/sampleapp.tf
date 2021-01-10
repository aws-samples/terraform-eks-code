resource "kubernetes_namespace" "game-2048" {
    metadata {
        name = "game-2048"
    }
}


data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "kubernetes_deployment" "deployment-2048" {
  metadata {
    name = "deployment-2048"
    namespace="game-2048"
  }

  spec {
    replicas = 4

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "app-2048"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "app-2048"
        }
      }

      spec {
        container {
          image = format("%s.dkr.ecr.%s.amazonaws.com/sample-app",data.aws_caller_identity.current.account_id,data.aws_region.current.name)
          name  = "app-2048"
          image_pull_policy = "Always"
          port = ["80"]
        }
        #node_selector {
        #  alpha.eksctl.io/nodegroup-name =  "ng1-mycluster1"
        #}

      }
    }
  }
}