# kubernetes_secret_v1.sampleapp__orders-rabbitmq:
resource "kubernetes_secret_v1" "sampleapp__orders-rabbitmq" {
  immutable = false
  type      = "Opaque"

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "orders-rabbitmq"
    namespace     = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
