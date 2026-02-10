# UI Service - LoadBalancer
# Exposes the web UI to the internet via Network Load Balancer
# This is the main entry point for users to access the application

resource "kubernetes_service_v1" "sampleapp__ui" {
  metadata {
    annotations = {
      # Create internet-facing NLB (not internal)
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
    }
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "ui"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "ui"
      "helm.sh/chart"                = "ui-0.8.4"
    }
    name      = "ui"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "172.20.34.142"
    cluster_ips = [
      "172.20.34.142",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = "Cluster"
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv4",
    ]
    ip_family_policy            = "SingleStack"
    
    # Use EKS Auto Mode load balancer class
    # Auto Mode automatically provisions and manages the NLB
    load_balancer_class         = "eks.amazonaws.com/nlb"
    
    load_balancer_ip            = null
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    
    # Selector matches UI deployment pods
    selector = {
      "app.kuberneres.io/owner"     = "retail-store-sample"
      "app.kubernetes.io/component" = "service"
      "app.kubernetes.io/instance"  = "ui"
      "app.kubernetes.io/name"      = "ui"
    }
    session_affinity = "None"
    
    # LoadBalancer type creates external NLB
    type             = "LoadBalancer"

    port {
      app_protocol = null
      name         = "http"
      node_port    = 31139
      port         = 80  # External port (internet)
      protocol     = "TCP"
      target_port  = "http"  # Container port 8080
    }
  }
}
