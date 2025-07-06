# kubernetes_deployment_v1.sampleapp__catalog:
resource "kubernetes_deployment_v1" "sampleapp__catalog" {
  depends_on = [kubernetes_config_map_v1.sampleapp__catalog]
  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "catalog"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "catalog"
      "helm.sh/chart"                = "catalog-0.8.4"
    }
    name      = "catalog"
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
        "app.kuberneres.io/owner"     = "retail-store-sample"
        "app.kubernetes.io/component" = "service"
        "app.kubernetes.io/instance"  = "catalog"
        "app.kubernetes.io/name"      = "catalog"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "1"
      }
    }

    template {
      metadata {
        annotations = {
          "prometheus.io/path"   = "/metrics"
          "prometheus.io/port"   = "8080"
          "prometheus.io/scrape" = "true"
        }
        generate_name = null
        labels = {
          "app.kuberneres.io/owner"     = "retail-store-sample"
          "app.kubernetes.io/component" = "service"
          "app.kubernetes.io/instance"  = "catalog"
          "app.kubernetes.io/name"      = "catalog"
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
        service_account_name             = kubernetes_service_account_v1.sampleapp__catalog.metadata[0].name
        share_process_namespace          = false
        subdomain                        = null
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "public.ecr.aws/aws-containers/retail-store-sample-catalog:0.8.4"
          image_pull_policy          = "IfNotPresent"
          name                       = "catalog"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          env {
            name  = "DB_USER"
            value = null

            value_from {
              secret_key_ref {
                key      = "username"
                name     = "catalog-db"
                optional = false
              }
            }
          }
          env {
            name  = "DB_PASSWORD"
            value = null

            value_from {
              secret_key_ref {
                key      = "password"
                name     = "catalog-db"
                optional = false
              }
            }
          }

          env_from {
            prefix = null

            config_map_ref {
              name     = "catalog"
              optional = false
            }
          }

          liveness_probe {
            failure_threshold     = 3
            initial_delay_seconds = 30
            period_seconds        = 3
            success_threshold     = 1
            timeout_seconds       = 1

            http_get {
              host   = null
              path   = "/health"
              port   = "8080"
              scheme = "HTTP"
            }
          }

          port {
            container_port = 8080
            host_ip        = null
            name           = "http"
            protocol       = "TCP"
          }

          resources {
            limits = {
              "memory" = "256Mi"
            }
            requests = {
              "cpu"    = "128m"
              "memory" = "256Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = true
            run_as_group               = null
            run_as_non_root            = true
            run_as_user                = "1000"

            capabilities {
              add = []
              drop = [
                "ALL",
              ]
            }
          }

          volume_mount {
            mount_path        = "/tmp"
            mount_propagation = "None"
            name              = "tmp-volume"
            read_only         = false
            sub_path          = null
          }
        }

        security_context {
          fs_group               = "1000"
          fs_group_change_policy = null
          run_as_group           = null
          run_as_non_root        = false
          run_as_user            = null
          supplemental_groups    = []
        }

        volume {
          name = "tmp-volume"

          empty_dir {
            medium     = "Memory"
            size_limit = null
          }
        }
      }
    }
  }
}
