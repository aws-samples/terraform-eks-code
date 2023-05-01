resource "kubernetes_ingress_v1" "game-2048__ingress-2048" {
  wait_for_load_balancer = true
  depends_on = [kubernetes_namespace.game-2048]
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

output "load_balancer_hostname" {
  value = kubernetes_ingress_v1.game-2048__ingress-2048.status.0.load_balancer.0.ingress.0.hostname
}

# Display load balancer IP (typically present in GCP, or using Nginx ingress controller)
#output "load_balancer_ip" {
#  value = kubernetes_ingress_v1.game-2048__ingress-2048.status.0.load_balancer.0.ingress.0.ip
#}