resource "kubernetes_ingress" "game-2048__ingress-2048" {
  load_balancer_ingress = []

  metadata {
    annotations = {"kubernetes.io/ingress.class" = "alb"}
    annotations = {"alb.ingress.kubernetes.io/scheme" = "internal"}
    annotations = {"alb.ingress.kubernetes.io/target-type" = "ip"}
    #
    annotations = {"alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 8080}]"}
    labels      = {}
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


    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 8080}]'