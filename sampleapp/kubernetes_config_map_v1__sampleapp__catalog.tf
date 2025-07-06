# kubernetes_config_map_v1.sampleapp__catalog:
resource "kubernetes_config_map_v1" "sampleapp__catalog" {
  binary_data = {}
  data = {
    "DB_ENDPOINT"      = "catalog-mysql:3306"
    "DB_NAME"          = "catalog"
    "DB_READ_ENDPOINT" = "catalog-mysql:3306"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "catalog"
    namespace     = "sampleapp"
  }
}
