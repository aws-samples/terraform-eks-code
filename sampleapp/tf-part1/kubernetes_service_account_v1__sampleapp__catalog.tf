# kubernetes_service_account_v1.sampleapp__catalog:
resource "kubernetes_service_account_v1" "sampleapp__catalog" {
  automount_service_account_token = false

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "catalog"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "catalog"
      "helm.sh/chart"                = "catalog-0.8.4"
    }
    name      = "catalog"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}