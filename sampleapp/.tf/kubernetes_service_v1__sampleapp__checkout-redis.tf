# kubernetes_service_v1.sampleapp__checkout-redis:
resource "kubernetes_service_v1" "sampleapp__checkout-redis" {
  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kubernetes.io/component"  = "redis"
      "app.kubernetes.io/instance"   = "checkout"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "checkout"
      "helm.sh/chart"                = "checkout-0.8.4"
    }
    name      = "checkout-redis"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "172.20.2.255"
    cluster_ips = [
      "172.20.2.255",
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
      "app.kubernetes.io/component" = "redis"
      "app.kubernetes.io/instance"  = "checkout"
      "app.kubernetes.io/name"      = "checkout"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      app_protocol = null
      name         = "redis"
      node_port    = 0
      port         = 6379
      protocol     = "TCP"
      target_port  = "redis"
    }
  }
}
