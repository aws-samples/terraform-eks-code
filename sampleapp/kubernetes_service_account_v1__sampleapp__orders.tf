# kubernetes_service_account_v1.sampleapp__orders:
resource "kubernetes_service_account_v1" "sampleapp__orders" {
  automount_service_account_token = false

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "orders"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "orders"
      "helm.sh/chart"                = "orders-0.8.4"
    }
    name      = "orders"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}