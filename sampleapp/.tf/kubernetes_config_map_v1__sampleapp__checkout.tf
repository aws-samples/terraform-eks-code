# kubernetes_config_map_v1.sampleapp__checkout:
resource "kubernetes_config_map_v1" "sampleapp__checkout" {
  binary_data = {}
  data = {
    "ENDPOINTS_ORDERS" = "http://orders:80"
    "REDIS_URL"        = "redis://checkout-redis:6379"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "checkout"
    namespace     = "sampleapp"
  }
}
