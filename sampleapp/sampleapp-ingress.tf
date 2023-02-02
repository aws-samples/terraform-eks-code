resource "kubernetes_ingress_v1" "game-2048__ingress-2048" {
  #wait_for_load_balancer = true
  metadata {
    annotations = { "alb.ingress.kubernetes.io/scheme" = "internal", "alb.ingress.kubernetes.io/target-type" = "ip", "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 8080}]" }
    name        = "ingress-2048"
    namespace   = "game-2048"
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path = "/"
          backend {
            service {
              name = "service-2048"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}