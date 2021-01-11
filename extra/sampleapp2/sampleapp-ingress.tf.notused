resource "kubernetes_ingress" "game-2048__ingress-2048" {
  metadata {
    annotations = {"kubernetes.io/ingress.class" = "alb", "alb.ingress.kubernetes.io/scheme" = "internal", "alb.ingress.kubernetes.io/target-type" = "ip", "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 8080}]" }
    name        = "ingress-2048"
    namespace   = "game-2048"
  }

  spec {

    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = "service-2048"
            service_port = "80"
          }
        }
      }
    }
  }
}
