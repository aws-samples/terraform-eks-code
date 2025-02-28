# kubernetes_ingress_v1.keycloak__ingress-keycloak:
resource "kubernetes_ingress_v1" "keycloak__ingress-keycloak" {
  metadata {
    annotations = {}
    labels = {
      "app" = "app-keycloak"
    }
    name      = "ingress-keycloak"
    namespace = "keycloak"
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = "keycloak.testdomain.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "keycloak"

              port {
                number = 8080
              }
            }
          }
        }
      }
    }

    tls {
      hosts = [
        "keycloak.testdomain.local",
      ]
    }
  }

  timeouts {}
}