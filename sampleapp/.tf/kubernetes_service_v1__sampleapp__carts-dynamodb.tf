# kubernetes_service_v1.sampleapp__carts-dynamodb:
resource "kubernetes_service_v1" "sampleapp__carts-dynamodb" {
  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kubernetes.io/component"  = "dynamodb"
      "app.kubernetes.io/instance"   = "carts"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "carts"
      "helm.sh/chart"                = "carts-0.8.4"
    }
    name      = "carts-dynamodb"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "172.20.83.65"
    cluster_ips = [
      "172.20.83.65",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv4",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_class         = null
    load_balancer_ip            = null
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app.kubernetes.io/component" = "dynamodb"
      "app.kubernetes.io/instance"  = "carts"
      "app.kubernetes.io/name"      = "carts"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      app_protocol = null
      name         = "dynamodb"
      node_port    = 0
      port         = 8000
      protocol     = "TCP"
      target_port  = "dynamodb"
    }
  }
}
