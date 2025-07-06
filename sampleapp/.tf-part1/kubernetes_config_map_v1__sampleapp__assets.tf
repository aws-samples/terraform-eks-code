# kubernetes_config_map_v1.sampleapp__assets:
resource "kubernetes_config_map_v1" "sampleapp__assets" {
  binary_data = {}
  data = {
    "PORT" = "8080"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "assets"
    namespace     = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
