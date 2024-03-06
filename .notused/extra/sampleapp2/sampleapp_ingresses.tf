resource "kubernetes_ingress_v1" "game1-2048__ingress1-2048" {
  #wait_for_load_balancer = true
  metadata {
    annotations = { "alb.ingress.kubernetes.io/scheme" = "internal", "alb.ingress.kubernetes.io/target-type" = "ip", "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 8081}]" }
    name        = "ingress1-2048"
    namespace   = "game1-2048"
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path = "/"
          backend {
            service {
              name = "service1-2048"
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

resource "kubernetes_ingress_v1" "game2-2048__ingress2-2048" {
  #wait_for_load_balancer = true
  metadata {
    annotations = { "alb.ingress.kubernetes.io/scheme" = "internal", "alb.ingress.kubernetes.io/target-type" = "ip", "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 8082}]" }
    name        = "ingress2-2048"
    namespace   = "game2-2048"
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path = "/"
          backend {
            service {
              name = "service2-2048"
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



