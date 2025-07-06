# kubernetes_stateful_set_v1.sampleapp__orders-rabbitmq:
resource "kubernetes_stateful_set_v1" "sampleapp__orders-rabbitmq" {
  depends_on=[kubernetes_secret_v1.sampleapp__orders-rabbitmq]
  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kubernetes.io/component"  = "rabbitmq"
      "app.kubernetes.io/instance"   = "orders"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "orders"
      "helm.sh/chart"                = "orders-0.8.4"
    }
    name      = "orders-rabbitmq"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    min_ready_seconds      = 0
    pod_management_policy  = "OrderedReady"
    replicas               = "1"
    revision_history_limit = 10
    service_name           = "orders-rabbitmq"

    persistent_volume_claim_retention_policy {
      when_deleted = "Retain"
      when_scaled  = "Retain"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/component" = "rabbitmq"
        "app.kubernetes.io/instance"  = "orders"
        "app.kubernetes.io/name"      = "orders"
      }
    }

    template {
      metadata {
        annotations   = {}
        generate_name = null
        labels = {
          "app.kubernetes.io/component" = "rabbitmq"
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
          image                      = "public.ecr.aws/docker/library/rabbitmq:3-management"
          image_pull_policy          = "IfNotPresent"
          name                       = "rabbitmq"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          port {
            container_port = 5672
            host_ip        = null
            name           = "amqp"
            protocol       = "TCP"
          }
          port {
            container_port = 15672
            host_ip        = null
            name           = "http"
            protocol       = "TCP"
          }

          resources {
            limits   = {}
            requests = {}
          }

          volume_mount {
            mount_path        = "/var/lib/rabbitmq/mnesia"
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
