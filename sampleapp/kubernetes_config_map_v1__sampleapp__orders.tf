# kubernetes_config_map_v1.sampleapp__orders:
resource "kubernetes_config_map_v1" "sampleapp__orders" {
  binary_data = {}
  data = {
    "RETAIL_ORDERS_MESSAGING_PROVIDER" = "rabbitmq"
    "SPRING_DATASOURCE_URL"            = "jdbc:postgresql://orders-postgresql:5432/orders"
    "SPRING_RABBITMQ_ADDRESSES"        = "amqp://orders-rabbitmq:5672"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "orders"
    namespace     = "sampleapp"
  }
}
