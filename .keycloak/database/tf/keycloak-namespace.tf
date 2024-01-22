resource "kubernetes_namespace" "keycloak" {
  metadata {
    annotations = {
      name = "keycloak"
    }

    labels = {
      mylabel = "keycloak"
    }

    name = "keycloak"
  }