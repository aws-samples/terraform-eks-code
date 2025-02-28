resource "kubernetes_namespace_v1" "keycloak" {
  metadata {
    annotations = {
      name = "keycloak"
    }

    labels = {
      mylabel = "keycloak"
    }

    name = "keycloak"
  }