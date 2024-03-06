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

