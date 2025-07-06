# kubernetes_config_map_v1.sampleapp__carts:
resource "kubernetes_config_map_v1" "sampleapp__carts" {
  binary_data = {}
  data = {
    "AWS_ACCESS_KEY_ID"          = "key"
    "AWS_SECRET_ACCESS_KEY"      = "secret"
    "CARTS_DYNAMODB_CREATETABLE" = "true"
    "CARTS_DYNAMODB_ENDPOINT"    = "http://carts-dynamodb:8000"
    "CARTS_DYNAMODB_TABLENAME"   = "Items"
    "SPRING_PROFILES_ACTIVE"     = "dynamodb"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "carts"
    namespace     = "sampleapp"
  }
}
