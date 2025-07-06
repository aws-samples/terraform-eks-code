# kubernetes_service_account_v1.sampleapp__default:
resource "kubernetes_service_account_v1" "sampleapp__default" {
  automount_service_account_token = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "default"
    namespace     = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
