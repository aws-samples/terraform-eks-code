# kubernetes_secret_v1.sampleapp__orders-db:
resource "kubernetes_secret_v1" "sampleapp__orders-db" {
  data = {
    username = "b3JkZXJz"
    password = "QTRZNWY4Q1djU1hZaWloYw=="
  }
  immutable = false
  type      = "Opaque"

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "orders-db"
    namespace     = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
