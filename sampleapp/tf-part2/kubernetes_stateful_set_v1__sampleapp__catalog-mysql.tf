# kubernetes_stateful_set_v1.sampleapp__catalog-mysql:
resource "kubernetes_stateful_set_v1" "sampleapp__catalog-mysql" {

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kubernetes.io/component"  = "mysql"
      "app.kubernetes.io/instance"   = "catalog"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "catalog"
      "helm.sh/chart"                = "catalog-0.8.4"
    }
    name      = "catalog-mysql"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    min_ready_seconds      = 0
    pod_management_policy  = "OrderedReady"
    replicas               = "1"
    revision_history_limit = 10
    service_name           = kubernetes_service_v1.sampleapp__catalog-mysql.metadata[0].name

    persistent_volume_claim_retention_policy {
      when_deleted = "Retain"
      when_scaled  = "Retain"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/component" = "mysql"
        "app.kubernetes.io/instance"  = "catalog"
        "app.kubernetes.io/name"      = "catalog"
      }
    }

    template {
      metadata {
        annotations   = {}
        generate_name = null
        labels = {
          "app.kubernetes.io/component" = "mysql"
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
        service_account_name             = null
        share_process_namespace          = false
        subdomain                        = null
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "public.ecr.aws/docker/library/mysql:8.0"
          image_pull_policy          = "IfNotPresent"
          name                       = "mysql"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "my-secret-pw"
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "catalog"
          }
          env {
            name  = "MYSQL_USER"
            value = null

            value_from {
              secret_key_ref {
                key      = "username"
                name     = kubernetes_secret_v1.sampleapp__catalog-db.metadata[0].name
                optional = false
              }
            }
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = null

            value_from {
              secret_key_ref {
                key      = "password"
                name     = kubernetes_secret_v1.sampleapp__catalog-db.metadata[0].name
                optional = false
              }
            }
          }

          port {
            container_port = 3306
            host_ip        = null
            name           = "mysql"
            protocol       = "TCP"
          }

          resources {
            limits   = {}
            requests = {}
          }

          volume_mount {
            mount_path        = "/var/lib/mysql"
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
