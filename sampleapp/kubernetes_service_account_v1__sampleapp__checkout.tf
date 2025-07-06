# kubernetes_service_account_v1.sampleapp__checkout:
resource "kubernetes_service_account_v1" "sampleapp__checkout" {
  automount_service_account_token = false

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "checkout"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "checkout"
      "helm.sh/chart"                = "checkout-0.8.4"
    }
    name      = "checkout"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
