# kubernetes_service_account_v1.sampleapp__assets:
resource "kubernetes_service_account_v1" "sampleapp__assets" {
  automount_service_account_token = false

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "assets"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "assets"
      "helm.sh/chart"                = "assets-0.8.4"
    }
    name      = "assets"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}