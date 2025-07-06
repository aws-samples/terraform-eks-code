# kubernetes_service_v1.sampleapp__orders-postgresql:
resource "kubernetes_service_v1" "sampleapp__orders-postgresql" {
  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kubernetes.io/component"  = "postgresql"
      "app.kubernetes.io/instance"   = "orders"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "orders"
      "helm.sh/chart"                = "orders-0.8.4"
    }
    name      = "orders-postgresql"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "172.20.7.166"
    cluster_ips = [
      "172.20.7.166",
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
      "app.kubernetes.io/component" = "postgresql"
      "app.kubernetes.io/instance"  = "orders"
      "app.kubernetes.io/name"      = "orders"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      app_protocol = null
      name         = "postgresql"
      node_port    = 0
      port         = 5432
      protocol     = "TCP"
      target_port  = "postgresql"
    }
  }
}
