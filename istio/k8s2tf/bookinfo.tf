resource "kubernetes_namespace_v1" "sample" {
  depends_on=[null_resource.restart]
  metadata {
    annotations = {}
    labels = {
      "istio-injection" = "enabled"
    }
    name = "sample"
  }

  timeouts {}
}


# kubernetes_service_account_v1.sample__bookinfo-details:
resource "kubernetes_service_account_v1" "sample__bookinfo-details" {
  automount_service_account_token = false

  metadata {
    annotations = {}
    labels = {
      "account" = "details"
    }
    name      = "bookinfo-details"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  timeouts {}
}

# kubernetes_service_account_v1.sample__bookinfo-productpage:
resource "kubernetes_service_account_v1" "sample__bookinfo-productpage" {
  automount_service_account_token = false

  metadata {
    annotations = {}
    labels = {
      "account" = "productpage"
    }
    name      = "bookinfo-productpage"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  timeouts {}
}

# kubernetes_service_account_v1.sample__bookinfo-ratings:
resource "kubernetes_service_account_v1" "sample__bookinfo-ratings" {
  automount_service_account_token = false

  metadata {
    annotations = {}
    labels = {
      "account" = "ratings"
    }
    name      = "bookinfo-ratings"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  timeouts {}
}

# kubernetes_service_account_v1.sample__bookinfo-reviews:
resource "kubernetes_service_account_v1" "sample__bookinfo-reviews" {
  automount_service_account_token = false

  metadata {
    annotations = {}
    labels = {
      "account" = "reviews"
    }
    name      = "bookinfo-reviews"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  timeouts {}
}

# kubernetes_service_account_v1.sample__default:
resource "kubernetes_service_account_v1" "sample__default" {
  automount_service_account_token = false

  metadata {
    annotations = {}
    labels      = {}
    name        = "default"
    namespace   = kubernetes_namespace_v1.sample.metadata[0].name
  }

  timeouts {}
}

# kubernetes_service_v1.sample__details:
resource "kubernetes_service_v1" "sample__details" {
  metadata {
    annotations = {}
    labels = {
      "app"     = "details"
      "service" = "details"
    }
    name      = "details"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
    wait_for_load_balancer = true
  }

  spec {
    allocate_load_balancer_node_ports = true
    #cluster_ip                        = "172.20.166.147"
    #cluster_ips = [
    #  "172.20.166.147",
    #]
    external_ips            = []
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv4",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app" = "details"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      name        = "http"
      node_port   = 0
      port        = 9080
      protocol    = "TCP"
      target_port = "9080"
    }
  }

  wait_for_load_balancer = true
  timeouts {}
}

# kubernetes_service_v1.sample__productpage:
resource "kubernetes_service_v1" "sample__productpage" {
  metadata {
    annotations = {}
    labels = {
      "app"     = "productpage"
      "service" = "productpage"
    }
    name      = "productpage"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    #cluster_ip                        = "172.20.170.136"
    #cluster_ips = [
    #  "172.20.170.136",
    #]
    external_ips            = []
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv4",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app" = "productpage"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      name        = "http"
      node_port   = 0
      port        = 9080
      protocol    = "TCP"
      target_port = "9080"
    }
  }

  wait_for_load_balancer = true
  timeouts {}
}

# kubernetes_service_v1.sample__ratings:
resource "kubernetes_service_v1" "sample__ratings" {
  metadata {
    annotations = {}
    labels = {
      "app"     = "ratings"
      "service" = "ratings"
    }
    name      = "ratings"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    #cluster_ip                        = "172.20.229.10"
    #cluster_ips = [
    #  "172.20.229.10",
    #]
    external_ips            = []
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv4",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app" = "ratings"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      name        = "http"
      node_port   = 0
      port        = 9080
      protocol    = "TCP"
      target_port = "9080"
    }
  }

  wait_for_load_balancer = true
  timeouts {}
}

# kubernetes_service_v1.sample__reviews:
resource "kubernetes_service_v1" "sample__reviews" {
  metadata {
    annotations = {}
    labels = {
      "app"     = "reviews"
      "service" = "reviews"
    }
    name      = "reviews"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    #cluster_ip                        = "172.20.51.117"
    #cluster_ips = [
    #  "172.20.51.117",
    #]
    external_ips            = []
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv4",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app" = "reviews"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      name        = "http"
      node_port   = 0
      port        = 9080
      protocol    = "TCP"
      target_port = "9080"
    }
  }

  wait_for_load_balancer = true
  timeouts {}
}


# kubernetes_deployment_v1.sample__details-v1:
resource "kubernetes_deployment_v1" "sample__details-v1" {

  metadata {
    annotations = {}
    labels = {
      "app"     = "details"
      "version" = "v1"
    }
    name      = "details-v1"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  spec {
    min_ready_seconds         = 0
    paused                    = false
    progress_deadline_seconds = 600
    replicas                  = "1"
    revision_history_limit    = 10

    selector {
      match_labels = {
        "app"     = "details"
        "version" = "v1"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        annotations = {}
        labels = {
          "app"     = "details"
          "version" = "v1"
        }
      }
      spec {
        automount_service_account_token  = false
        dns_policy                       = "ClusterFirst"
        enable_service_links             = false
        host_ipc                         = false
        host_network                     = false
        host_pid                         = false
        node_selector                    = {}
        restart_policy                   = "Always"
        scheduler_name                   = "default-scheduler"
        service_account_name             = kubernetes_service_account_v1.sample__default.metadata.name
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "docker.io/istio/examples-bookinfo-details-v1:1.18.0"
          image_pull_policy          = "IfNotPresent"
          name                       = "details"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false

          port {
            container_port = 9080
            protocol       = "TCP"
          }

          resources {
            limits   = {}
            requests = {}
          }
        }
      }
    }
  }

  timeouts {}
}

# kubernetes_deployment_v1.sample__productpage-v1:
resource "kubernetes_deployment_v1" "sample__productpage-v1" {

  metadata {
    annotations = {}
    labels = {
      "app"     = "productpage"
      "version" = "v1"
    }
    name      = "productpage-v1"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  spec {
    min_ready_seconds         = 0
    paused                    = false
    progress_deadline_seconds = 600
    replicas                  = "1"
    revision_history_limit    = 10

    selector {
      match_labels = {
        "app"     = "productpage"
        "version" = "v1"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        annotations = {}
        labels = {
          "app"     = "productpage"
          "version" = "v1"
        }
      }
      spec {
        automount_service_account_token  = false
        dns_policy                       = "ClusterFirst"
        enable_service_links             = false
        host_ipc                         = false
        host_network                     = false
        host_pid                         = false
        node_selector                    = {}
        restart_policy                   = "Always"
        scheduler_name                   = "default-scheduler"
        service_account_name             = kubernetes_service_account_v1.sample__bookinfo-productpage.metadata.name
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "docker.io/istio/examples-bookinfo-productpage-v1:1.18.0"
          image_pull_policy          = "IfNotPresent"
          name                       = "productpage"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false

          port {
            container_port = 9080
            protocol       = "TCP"
          }

          resources {
            limits   = {}
            requests = {}
          }

          volume_mount {
            mount_path        = "/tmp"
            mount_propagation = "None"
            name              = "tmp"
            read_only         = false
          }
        }

        volume {
          name = "tmp"

          empty_dir {}
        }
      }
    }
  }

  timeouts {}
}

# kubernetes_deployment_v1.sample__ratings-v1:
resource "kubernetes_deployment_v1" "sample__ratings-v1" {

  metadata {
    annotations = {}
    labels = {
      "app"     = "ratings"
      "version" = "v1"
    }
    name      = "ratings-v1"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  spec {
    min_ready_seconds         = 0
    paused                    = false
    progress_deadline_seconds = 600
    replicas                  = "1"
    revision_history_limit    = 10

    selector {
      match_labels = {
        "app"     = "ratings"
        "version" = "v1"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        annotations = {}
        labels = {
          "app"     = "ratings"
          "version" = "v1"
        }
      }
      spec {
        automount_service_account_token  = false
        dns_policy                       = "ClusterFirst"
        enable_service_links             = false
        host_ipc                         = false
        host_network                     = false
        host_pid                         = false
        node_selector                    = {}
        restart_policy                   = "Always"
        scheduler_name                   = "default-scheduler"
        service_account_name             = kubernetes_service_account_v1.sample__bookinfo-ratings.metadata.name
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "docker.io/istio/examples-bookinfo-ratings-v1:1.18.0"
          image_pull_policy          = "IfNotPresent"
          name                       = "ratings"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false

          port {
            container_port = 9080
            protocol       = "TCP"
          }

          resources {
            limits   = {}
            requests = {}
          }
        }
      }
    }
  }

  timeouts {}
}

# kubernetes_deployment_v1.sample__reviews-v1:
resource "kubernetes_deployment_v1" "sample__reviews-v1" {

  metadata {
    annotations = {}
    labels = {
      "app"     = "reviews"
      "version" = "v1"
    }
    name      = "reviews-v1"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  spec {
    min_ready_seconds         = 0
    paused                    = false
    progress_deadline_seconds = 600
    replicas                  = "1"
    revision_history_limit    = 10

    selector {
      match_labels = {
        "app"     = "reviews"
        "version" = "v1"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        annotations = {}
        labels = {
          "app"     = "reviews"
          "version" = "v1"
        }
      }
      spec {
        automount_service_account_token  = false
        dns_policy                       = "ClusterFirst"
        enable_service_links             = false
        host_ipc                         = false
        host_network                     = false
        host_pid                         = false
        node_selector                    = {}
        restart_policy                   = "Always"
        scheduler_name                   = "default-scheduler"
        service_account_name             = kubernetes_service_account_v1.sample__bookinfo-reviews.metadata.name
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "docker.io/istio/examples-bookinfo-reviews-v1:1.18.0"
          image_pull_policy          = "IfNotPresent"
          name                       = "reviews"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false

          env {
            name  = "LOG_DIR"
            value = "/tmp/logs"
          }

          port {
            container_port = 9080
            protocol       = "TCP"
          }

          resources {
            limits   = {}
            requests = {}
          }

          volume_mount {
            mount_path        = "/tmp"
            mount_propagation = "None"
            name              = "tmp"
            read_only         = false
          }
          volume_mount {
            mount_path        = "/opt/ibm/wlp/output"
            mount_propagation = "None"
            name              = "wlp-output"
            read_only         = false
          }
        }

        volume {
          name = "wlp-output"

          empty_dir {}
        }
        volume {
          name = "tmp"

          empty_dir {}
        }
      }
    }
  }

  timeouts {}
}

# kubernetes_deployment_v1.sample__reviews-v2:
resource "kubernetes_deployment_v1" "sample__reviews-v2" {

  metadata {
    annotations = {}
    labels = {
      "app"     = "reviews"
      "version" = "v2"
    }
    name      = "reviews-v2"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  spec {
    min_ready_seconds         = 0
    paused                    = false
    progress_deadline_seconds = 600
    replicas                  = "1"
    revision_history_limit    = 10

    selector {
      match_labels = {
        "app"     = "reviews"
        "version" = "v2"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        annotations = {}
        labels = {
          "app"     = "reviews"
          "version" = "v2"
        }
      }
      spec {
        automount_service_account_token  = false
        dns_policy                       = "ClusterFirst"
        enable_service_links             = false
        host_ipc                         = false
        host_network                     = false
        host_pid                         = false
        node_selector                    = {}
        restart_policy                   = "Always"
        scheduler_name                   = "default-scheduler"
        service_account_name             = kubernetes_service_account_v1.sample__bookinfo-reviews.metadata.name
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "docker.io/istio/examples-bookinfo-reviews-v2:1.18.0"
          image_pull_policy          = "IfNotPresent"
          name                       = "reviews"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false

          env {
            name  = "LOG_DIR"
            value = "/tmp/logs"
          }

          port {
            container_port = 9080
            protocol       = "TCP"
          }

          resources {
            limits   = {}
            requests = {}
          }

          volume_mount {
            mount_path        = "/tmp"
            mount_propagation = "None"
            name              = "tmp"
            read_only         = false
          }
          volume_mount {
            mount_path        = "/opt/ibm/wlp/output"
            mount_propagation = "None"
            name              = "wlp-output"
            read_only         = false
          }
        }

        volume {
          name = "wlp-output"

          empty_dir {}
        }
        volume {
          name = "tmp"

          empty_dir {}
        }
      }
    }
  }

  timeouts {}
}

# kubernetes_deployment_v1.sample__reviews-v3:
resource "kubernetes_deployment_v1" "sample__reviews-v3" {

  metadata {
    annotations = {}
    labels = {
      "app"     = "reviews"
      "version" = "v3"
    }
    name      = "reviews-v3"
    namespace = kubernetes_namespace_v1.sample.metadata[0].name
  }

  spec {
    min_ready_seconds         = 0
    paused                    = false
    progress_deadline_seconds = 600
    replicas                  = "1"
    revision_history_limit    = 10

    selector {
      match_labels = {
        "app"     = "reviews"
        "version" = "v3"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        annotations = {}
        labels = {
          "app"     = "reviews"
          "version" = "v3"
        }
      }
      spec {
        automount_service_account_token  = false
        dns_policy                       = "ClusterFirst"
        enable_service_links             = false
        host_ipc                         = false
        host_network                     = false
        host_pid                         = false
        node_selector                    = {}
        restart_policy                   = "Always"
        scheduler_name                   = "default-scheduler"
        service_account_name             = kubernetes_service_account_v1.sample__bookinfo-reviews.metadata.name
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "docker.io/istio/examples-bookinfo-reviews-v3:1.18.0"
          image_pull_policy          = "IfNotPresent"
          name                       = "reviews"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false

          env {
            name  = "LOG_DIR"
            value = "/tmp/logs"
          }

          port {
            container_port = 9080
            protocol       = "TCP"
          }

          resources {
            limits   = {}
            requests = {}
          }

          volume_mount {
            mount_path        = "/tmp"
            mount_propagation = "None"
            name              = "tmp"
            read_only         = false
          }
          volume_mount {
            mount_path        = "/opt/ibm/wlp/output"
            mount_propagation = "None"
            name              = "wlp-output"
            read_only         = false
          }
        }

        volume {
          name = "wlp-output"

          empty_dir {}
        }
        volume {
          name = "tmp"

          empty_dir {}
        }
      }
    }
  }

  timeouts {}
}


