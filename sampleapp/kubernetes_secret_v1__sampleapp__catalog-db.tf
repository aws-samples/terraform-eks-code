# kubernetes_secret_v1.sampleapp__catalog-db:
resource "kubernetes_secret_v1" "sampleapp__catalog-db" {
  data = {
    username = "Y2F0YWxvZw=="
    password = "NVlGTWRva2taTWVDeWhpaw=="
  }
  immutable = false
  type      = "Opaque"

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "catalog-db"
    namespace     = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
