# kubernetes_service_v1.keycloak__keycloak:
resource "kubernetes_service_v1" "keycloak__keycloak" {
  metadata {
    annotations = {}
    labels = {
      "app" = "keycloak"
    }
    name      = "keycloak"
    namespace = "keycloak"
  }

  spec {
    selector = {
      "app" = "keycloak"
    }
    type             = "NodePort"

    port {
      name        = "http"
      port        = 8080
      protocol    = "TCP"
      target_port = "8080"
    }
  }

  wait_for_load_balancer = true
  timeouts {}
}