# kubernetes_deployment_v1.sampleapp__checkout-redis:
resource "kubernetes_deployment_v1" "sampleapp__checkout-redis" {

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
    min_ready_seconds         = 0
    paused                    = false
    progress_deadline_seconds = 600
    replicas                  = "1"
    revision_history_limit    = 10

    selector {
      match_labels = {
        "app.kubernetes.io/component" = "redis"
        "app.kubernetes.io/instance"  = "checkout"
        "app.kubernetes.io/name"      = "checkout"
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
        annotations   = {}
        generate_name = null
        labels = {
          "app.kubernetes.io/component" = "redis"
          "app.kubernetes.io/instance"  = "checkout"
          "app.kubernetes.io/name"      = "checkout"
        }
        name      = null
        namespace = null
      }
      spec {
        automount_service_account_token  = false
        dns_policy                       = "ClusterFirst"
        enable_service_links             = false
        host_ipc                         = false
        host_network                     = false
        host_pid                         = false
        hostname                         = null
        node_name                        = null
        node_selector                    = {}
        priority_class_name              = null
        restart_policy                   = "Always"
        runtime_class_name               = null
        scheduler_name                   = "default-scheduler"
        service_account_name             = null
        share_process_namespace          = false
        subdomain                        = null
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "redis:6.0-alpine"
          image_pull_policy          = "IfNotPresent"
          name                       = "redis"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          port {
            container_port = 6379
            host_ip        = null
            name           = "redis"
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
}
