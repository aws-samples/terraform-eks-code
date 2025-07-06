# kubernetes_config_map_v1.sampleapp__ui:
resource "kubernetes_config_map_v1" "sampleapp__ui" {
  binary_data = {}
  data = {
    "ENDPOINTS_ASSETS"   = "http://assets"
    "ENDPOINTS_CARTS"    = "http://carts"
    "ENDPOINTS_CATALOG"  = "http://catalog"
    "ENDPOINTS_CHECKOUT" = "http://checkout"
    "ENDPOINTS_ORDERS"   = "http://orders"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "ui"
    namespace     = "sampleapp"
  }
}
