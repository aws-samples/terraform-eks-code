# kubernetes_service_v1.sampleapp__checkout:
resource "kubernetes_service_v1" "sampleapp__checkout" {
  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "checkout"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "checkout"
      "helm.sh/chart"                = "checkout-0.8.4"
    }
    name      = "checkout"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "172.20.33.183"
    cluster_ips = [
      "172.20.33.183",
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
      "app.kuberneres.io/owner"     = "retail-store-sample"
      "app.kubernetes.io/component" = "service"
      "app.kubernetes.io/instance"  = "checkout"
      "app.kubernetes.io/name"      = "checkout"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      app_protocol = null
      name         = "http"
      node_port    = 0
      port         = 80
      protocol     = "TCP"
      target_port  = "http"
    }
  }
}
