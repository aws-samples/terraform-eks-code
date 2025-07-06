# kubernetes_stateful_set_v1.sampleapp__orders-postgresql:
resource "kubernetes_stateful_set_v1" "sampleapp__orders-postgresql" {

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
    min_ready_seconds      = 0
    pod_management_policy  = "OrderedReady"
    replicas               = "1"
    revision_history_limit = 10
    service_name           = "orders-postgresql"

    persistent_volume_claim_retention_policy {
      when_deleted = "Retain"
      when_scaled  = "Retain"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/component" = "postgresql"
        "app.kubernetes.io/instance"  = "orders"
        "app.kubernetes.io/name"      = "orders"
      }
    }

    template {
      metadata {
        annotations   = {}
        generate_name = null
        labels = {
          "app.kubernetes.io/component" = "postgresql"
          "app.kubernetes.io/instance"  = "orders"
          "app.kubernetes.io/name"      = "orders"
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
          image                      = "public.ecr.aws/docker/library/postgres:16.1"
          image_pull_policy          = "IfNotPresent"
          name                       = "postgresql"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          env {
            name  = "POSTGRES_DB"
            value = "orders"
          }
          env {
            name  = "POSTGRES_USER"
            value = null

            value_from {
              secret_key_ref {
                key      = "username"
                name     = "orders-db"
                optional = false
              }
            }
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = null

            value_from {
              secret_key_ref {
                key      = "password"
                name     = "orders-db"
                optional = false
              }
            }
          }
          env {
            name  = "PGDATA"
            value = "/data/pgdata"
          }

          port {
            container_port = 5432
            host_ip        = null
            name           = "postgresql"
            protocol       = "TCP"
          }

          resources {
            limits   = {}
            requests = {}
          }

          volume_mount {
            mount_path        = "/data"
            mount_propagation = "None"
            name              = "data"
            read_only         = false
            sub_path          = null
          }
        }

        volume {
          name = "data"

          empty_dir {
            medium     = null
            size_limit = null
          }
        }
      }
    }
  }
}
