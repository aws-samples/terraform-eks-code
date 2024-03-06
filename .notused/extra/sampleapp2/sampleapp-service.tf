resource "kubernetes_service" "game1-2048__service1-2048" {

  metadata {
    name      = "service1-2048"
    namespace = "game1-2048"
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "app1-2048"
    }

    type = "NodePort"

    port {
      port        = 80
      protocol    = "TCP"
      target_port = "80"
    }
  }

}


resource "kubernetes_service" "game2-2048__service2-2048" {

  metadata {
    name      = "service2-2048"
    namespace = "game2-2048"
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "app2-2048"
    }

    type = "NodePort"

    port {
      port        = 80
      protocol    = "TCP"
      target_port = "80"
    }
  }

}

