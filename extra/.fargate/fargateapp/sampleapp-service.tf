resource "kubernetes_service" "fargate1__service-logger" {

  metadata {
    name      = "service-logging"
    namespace = "fargate1"
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "logging-server"
    }

    type = "NodePort"

    port {
      port        = 80
      protocol    = "TCP"
      target_port = "80"
    }
  }

}

