# kubernetes_service_account_v1.sampleapp__ui:
resource "kubernetes_service_account_v1" "sampleapp__ui" {
  automount_service_account_token = false

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "ui"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "ui"
      "helm.sh/chart"                = "ui-0.8.4"
    }
    name      = "ui"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}