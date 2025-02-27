terraform {
  required_version = ">= 1.9.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.36.0"
    }
  }
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}
# kubernetes_config_map_v1.sampleapp__assets:
resource "kubernetes_config_map_v1" "sampleapp__assets" {
  binary_data = {}
  data = {
    "PORT" = "8080"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "assets"
    namespace     = "sampleapp"
  }
}
# kubernetes_config_map_v1.sampleapp__carts:
resource "kubernetes_config_map_v1" "sampleapp__carts" {
  binary_data = {}
  data = {
    "AWS_ACCESS_KEY_ID"          = "key"
    "AWS_SECRET_ACCESS_KEY"      = "secret"
    "CARTS_DYNAMODB_CREATETABLE" = "true"
    "CARTS_DYNAMODB_ENDPOINT"    = "http://carts-dynamodb:8000"
    "CARTS_DYNAMODB_TABLENAME"   = "Items"
    "SPRING_PROFILES_ACTIVE"     = "dynamodb"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "carts"
    namespace     = "sampleapp"
  }
}
# kubernetes_config_map_v1.sampleapp__catalog:
resource "kubernetes_config_map_v1" "sampleapp__catalog" {
  binary_data = {}
  data = {
    "DB_ENDPOINT"      = "catalog-mysql:3306"
    "DB_NAME"          = "catalog"
    "DB_READ_ENDPOINT" = "catalog-mysql:3306"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "catalog"
    namespace     = "sampleapp"
  }
}
# kubernetes_config_map_v1.sampleapp__checkout:
resource "kubernetes_config_map_v1" "sampleapp__checkout" {
  binary_data = {}
  data = {
    "ENDPOINTS_ORDERS" = "http://orders:80"
    "REDIS_URL"        = "redis://checkout-redis:6379"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "checkout"
    namespace     = "sampleapp"
  }
}
# kubernetes_config_map_v1.sampleapp__orders:
resource "kubernetes_config_map_v1" "sampleapp__orders" {
  binary_data = {}
  data = {
    "RETAIL_ORDERS_MESSAGING_PROVIDER" = "rabbitmq"
    "SPRING_DATASOURCE_URL"            = "jdbc:postgresql://orders-postgresql:5432/orders"
    "SPRING_RABBITMQ_ADDRESSES"        = "amqp://orders-rabbitmq:5672"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "orders"
    namespace     = "sampleapp"
  }
}
# kubernetes_config_map_v1.sampleapp__ui:
resource "kubernetes_config_map_v1" "sampleapp__ui" {
  binary_data = {}
  data = {
    "ENDPOINTS_ASSETS"   = "http://assets"
    "ENDPOINTS_CARTS"    = "http://carts"
    "ENDPOINTS_CATALOG"  = "http://catalog"
    "ENDPOINTS_CHECKOUT" = "http://checkout"
    "ENDPOINTS_ORDERS"   = "http://orders"
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "ui"
    namespace     = "sampleapp"
  }
}
# kubernetes_deployment_v1.sampleapp__assets:
resource "kubernetes_deployment_v1" "sampleapp__assets" {

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "assets"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "assets"
      "helm.sh/chart"                = "assets-0.8.4"
    }
    name      = "assets"
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
        "app.kubernetes.io/instance"  = "assets"
        "app.kubernetes.io/name"      = "assets"
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
        annotations   = {}
        generate_name = null
        labels = {
          "app.kuberneres.io/owner"     = "retail-store-sample"
          "app.kubernetes.io/component" = "service"
          "app.kubernetes.io/instance"  = "assets"
          "app.kubernetes.io/name"      = "assets"
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
        service_account_name             = kubernetes_service_account_v1.sampleapp__assets.metadata[0].name
        share_process_namespace          = false
        subdomain                        = null
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "public.ecr.aws/aws-containers/retail-store-sample-assets:0.8.4"
          image_pull_policy          = "IfNotPresent"
          name                       = "assets"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          env_from {
            prefix = null

            config_map_ref {
              name     = "assets"
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
              path   = "/health.html"
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
              "memory" = "128Mi"
            }
            requests = {
              "cpu"    = "128m"
              "memory" = "128Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = false
            run_as_group               = null
            run_as_non_root            = false
            run_as_user                = null

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
# kubernetes_deployment_v1.sampleapp__carts-dynamodb:
resource "kubernetes_deployment_v1" "sampleapp__carts-dynamodb" {

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kubernetes.io/component"  = "dynamodb"
      "app.kubernetes.io/instance"   = "carts"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "carts"
      "helm.sh/chart"                = "carts-0.8.4"
    }
    name      = "carts-dynamodb"
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
        "app.kubernetes.io/component" = "dynamodb"
        "app.kubernetes.io/instance"  = "carts"
        "app.kubernetes.io/name"      = "carts"
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
          "app.kubernetes.io/component" = "dynamodb"
          "app.kubernetes.io/instance"  = "carts"
          "app.kubernetes.io/name"      = "carts"
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
          image                      = "amazon/dynamodb-local:1.20.0"
          image_pull_policy          = "IfNotPresent"
          name                       = "dynamodb"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          port {
            container_port = 8000
            host_ip        = null
            name           = "dynamodb"
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
# kubernetes_deployment_v1.sampleapp__carts:
resource "kubernetes_deployment_v1" "sampleapp__carts" {

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "carts"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "carts"
      "helm.sh/chart"                = "carts-0.8.4"
    }
    name      = "carts"
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
        "app.kubernetes.io/instance"  = "carts"
        "app.kubernetes.io/name"      = "carts"
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
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "8080"
          "prometheus.io/scrape" = "true"
        }
        generate_name = null
        labels = {
          "app.kuberneres.io/owner"     = "retail-store-sample"
          "app.kubernetes.io/component" = "service"
          "app.kubernetes.io/instance"  = "carts"
          "app.kubernetes.io/name"      = "carts"
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
        service_account_name             = kubernetes_service_account_v1.sampleapp__carts.metadata[0].name
        share_process_namespace          = false
        subdomain                        = null
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "public.ecr.aws/aws-containers/retail-store-sample-cart:0.8.4"
          image_pull_policy          = "IfNotPresent"
          name                       = "carts"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          env {
            name  = "JAVA_OPTS"
            value = "-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/urandom"
          }

          env_from {
            prefix = null

            config_map_ref {
              name     = "carts"
              optional = false
            }
          }

          liveness_probe {
            failure_threshold     = 3
            initial_delay_seconds = 45
            period_seconds        = 3
            success_threshold     = 1
            timeout_seconds       = 1

            http_get {
              host   = null
              path   = "/actuator/health/liveness"
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
              "memory" = "512Mi"
            }
            requests = {
              "cpu"    = "128m"
              "memory" = "512Mi"
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
# kubernetes_deployment_v1.sampleapp__catalog:
resource "kubernetes_deployment_v1" "sampleapp__catalog" {

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
# kubernetes_deployment_v1.sampleapp__checkout:
resource "kubernetes_deployment_v1" "sampleapp__checkout" {

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
    min_ready_seconds         = 0
    paused                    = false
    progress_deadline_seconds = 600
    replicas                  = "1"
    revision_history_limit    = 10

    selector {
      match_labels = {
        "app.kuberneres.io/owner"     = "retail-store-sample"
        "app.kubernetes.io/component" = "service"
        "app.kubernetes.io/instance"  = "checkout"
        "app.kubernetes.io/name"      = "checkout"
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
        service_account_name             = kubernetes_service_account_v1.sampleapp__checkout.metadata[0].name
        share_process_namespace          = false
        subdomain                        = null
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "public.ecr.aws/aws-containers/retail-store-sample-checkout:0.8.4"
          image_pull_policy          = "IfNotPresent"
          name                       = "checkout"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          env_from {
            prefix = null

            config_map_ref {
              name     = "checkout"
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
# kubernetes_deployment_v1.sampleapp__orders:
resource "kubernetes_deployment_v1" "sampleapp__orders" {

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "orders"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "orders"
      "helm.sh/chart"                = "orders-0.8.4"
    }
    name      = "orders"
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
        "app.kubernetes.io/instance"  = "orders"
        "app.kubernetes.io/name"      = "orders"
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
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "8080"
          "prometheus.io/scrape" = "true"
        }
        generate_name = null
        labels = {
          "app.kuberneres.io/owner"     = "retail-store-sample"
          "app.kubernetes.io/component" = "service"
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
        service_account_name             = kubernetes_service_account_v1.sampleapp__orders.metadata[0].name
        share_process_namespace          = false
        subdomain                        = null
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "public.ecr.aws/aws-containers/retail-store-sample-orders:0.8.4"
          image_pull_policy          = "IfNotPresent"
          name                       = "orders"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          env {
            name  = "JAVA_OPTS"
            value = "-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/urandom"
          }
          env {
            name  = "SPRING_DATASOURCE_USERNAME"
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
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = null

            value_from {
              secret_key_ref {
                key      = "password"
                name     = "orders-db"
                optional = false
              }
            }
          }

          env_from {
            prefix = null

            secret_ref {
              name     = "orders-rabbitmq"
              optional = false
            }
          }
          env_from {
            prefix = null

            config_map_ref {
              name     = "orders"
              optional = false
            }
          }

          liveness_probe {
            failure_threshold     = 3
            initial_delay_seconds = 45
            period_seconds        = 3
            success_threshold     = 1
            timeout_seconds       = 1

            http_get {
              host   = null
              path   = "/actuator/health/liveness"
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
              "memory" = "512Mi"
            }
            requests = {
              "cpu"    = "128m"
              "memory" = "512Mi"
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
# kubernetes_deployment_v1.sampleapp__ui:
resource "kubernetes_deployment_v1" "sampleapp__ui" {

  metadata {
    annotations   = {}
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
    min_ready_seconds         = 0
    paused                    = false
    progress_deadline_seconds = 600
    replicas                  = "1"
    revision_history_limit    = 10

    selector {
      match_labels = {
        "app.kuberneres.io/owner"     = "retail-store-sample"
        "app.kubernetes.io/component" = "service"
        "app.kubernetes.io/instance"  = "ui"
        "app.kubernetes.io/name"      = "ui"
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
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "8080"
          "prometheus.io/scrape" = "true"
        }
        generate_name = null
        labels = {
          "app.kuberneres.io/owner"     = "retail-store-sample"
          "app.kubernetes.io/component" = "service"
          "app.kubernetes.io/instance"  = "ui"
          "app.kubernetes.io/name"      = "ui"
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
        service_account_name             = kubernetes_service_account_v1.sampleapp__ui.metadata[0].name
        share_process_namespace          = false
        subdomain                        = null
        termination_grace_period_seconds = 30

        container {
          args                       = []
          command                    = []
          image                      = "public.ecr.aws/aws-containers/retail-store-sample-ui:0.8.4"
          image_pull_policy          = "IfNotPresent"
          name                       = "ui"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false
          working_dir                = null

          env {
            name  = "JAVA_OPTS"
            value = "-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/urandom"
          }

          env_from {
            prefix = null

            config_map_ref {
              name     = "ui"
              optional = false
            }
          }

          liveness_probe {
            failure_threshold     = 3
            initial_delay_seconds = 45
            period_seconds        = 3
            success_threshold     = 1
            timeout_seconds       = 1

            http_get {
              host   = null
              path   = "/actuator/health/liveness"
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
              "memory" = "512Mi"
            }
            requests = {
              "cpu"    = "128m"
              "memory" = "512Mi"
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
              add = [
                "NET_BIND_SERVICE",
              ]
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
# kubernetes_namespace_v1.sampleapp:
resource "kubernetes_namespace_v1" "sampleapp" {

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "sampleapp"
  }
}
# kubernetes_secret_v1.sampleapp__catalog-db:
resource "kubernetes_secret_v1" "sampleapp__catalog-db" {
  data = {
    username = "Y2F0YWxvZw=="
    password = "NVlGTWRva2taTWVDeWhpaw=="
  }
  immutable = false
  type      = "Opaque"

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "catalog-db"
    namespace     = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
# kubernetes_secret_v1.sampleapp__orders-db:
resource "kubernetes_secret_v1" "sampleapp__orders-db" {
  data = {
    username = "b3JkZXJz"
    password = "QTRZNWY4Q1djU1hZaWloYw=="
  }
  immutable = false
  type      = "Opaque"

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "orders-db"
    namespace     = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
# kubernetes_secret_v1.sampleapp__orders-rabbitmq:
resource "kubernetes_secret_v1" "sampleapp__orders-rabbitmq" {
  immutable = false
  type      = "Opaque"

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "orders-rabbitmq"
    namespace     = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
# kubernetes_service_account_v1.sampleapp__assets:
resource "kubernetes_service_account_v1" "sampleapp__assets" {
  automount_service_account_token = false

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "assets"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "assets"
      "helm.sh/chart"                = "assets-0.8.4"
    }
    name      = "assets"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
# kubernetes_service_account_v1.sampleapp__carts:
resource "kubernetes_service_account_v1" "sampleapp__carts" {
  automount_service_account_token = false

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "carts"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "carts"
      "helm.sh/chart"                = "carts-0.8.4"
    }
    name      = "carts"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
# kubernetes_service_account_v1.sampleapp__catalog:
resource "kubernetes_service_account_v1" "sampleapp__catalog" {
  automount_service_account_token = false

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
}
# kubernetes_service_account_v1.sampleapp__checkout:
resource "kubernetes_service_account_v1" "sampleapp__checkout" {
  automount_service_account_token = false

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
}
# kubernetes_service_account_v1.sampleapp__orders:
resource "kubernetes_service_account_v1" "sampleapp__orders" {
  automount_service_account_token = false

  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "orders"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "orders"
      "helm.sh/chart"                = "orders-0.8.4"
    }
    name      = "orders"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }
}
# kubernetes_service_account_v1.sampleapp__ui:
resource "kubernetes_service_account_v1" "sampleapp__ui" {
  automount_service_account_token = false

  metadata {
    annotations   = {}
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
}
# kubernetes_service_v1.sampleapp__assets:
resource "kubernetes_service_v1" "sampleapp__assets" {
  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "assets"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "assets"
      "helm.sh/chart"                = "assets-0.8.4"
    }
    name      = "assets"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "fdd3:4686:2baa::f8f0"
    cluster_ips = [
      "fdd3:4686:2baa::f8f0",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_class         = null
    load_balancer_ip            = null
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app.kuberneres.io/owner"     = "retail-store-sample"
      "app.kubernetes.io/component" = "service"
      "app.kubernetes.io/instance"  = "assets"
      "app.kubernetes.io/name"      = "assets"
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
# kubernetes_service_v1.sampleapp__carts-dynamodb:
resource "kubernetes_service_v1" "sampleapp__carts-dynamodb" {
  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kubernetes.io/component"  = "dynamodb"
      "app.kubernetes.io/instance"   = "carts"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "carts"
      "helm.sh/chart"                = "carts-0.8.4"
    }
    name      = "carts-dynamodb"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "fdd3:4686:2baa::9fc4"
    cluster_ips = [
      "fdd3:4686:2baa::9fc4",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_class         = null
    load_balancer_ip            = null
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app.kubernetes.io/component" = "dynamodb"
      "app.kubernetes.io/instance"  = "carts"
      "app.kubernetes.io/name"      = "carts"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      app_protocol = null
      name         = "dynamodb"
      node_port    = 0
      port         = 8000
      protocol     = "TCP"
      target_port  = "dynamodb"
    }
  }
}
# kubernetes_service_v1.sampleapp__carts:
resource "kubernetes_service_v1" "sampleapp__carts" {
  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "carts"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "carts"
      "helm.sh/chart"                = "carts-0.8.4"
    }
    name      = "carts"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "fdd3:4686:2baa::ca89"
    cluster_ips = [
      "fdd3:4686:2baa::ca89",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_class         = null
    load_balancer_ip            = null
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app.kuberneres.io/owner"     = "retail-store-sample"
      "app.kubernetes.io/component" = "service"
      "app.kubernetes.io/instance"  = "carts"
      "app.kubernetes.io/name"      = "carts"
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
# kubernetes_service_v1.sampleapp__catalog-mysql:
resource "kubernetes_service_v1" "sampleapp__catalog-mysql" {
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
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "fdd3:4686:2baa::762f"
    cluster_ips = [
      "fdd3:4686:2baa::762f",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_class         = null
    load_balancer_ip            = null
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app.kubernetes.io/component" = "mysql"
      "app.kubernetes.io/instance"  = "catalog"
      "app.kubernetes.io/name"      = "catalog"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      app_protocol = null
      name         = "mysql"
      node_port    = 0
      port         = 3306
      protocol     = "TCP"
      target_port  = "mysql"
    }
  }
}
# kubernetes_service_v1.sampleapp__catalog:
resource "kubernetes_service_v1" "sampleapp__catalog" {
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
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "fdd3:4686:2baa::acb3"
    cluster_ips = [
      "fdd3:4686:2baa::acb3",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_class         = null
    load_balancer_ip            = null
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app.kuberneres.io/owner"     = "retail-store-sample"
      "app.kubernetes.io/component" = "service"
      "app.kubernetes.io/instance"  = "catalog"
      "app.kubernetes.io/name"      = "catalog"
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
    cluster_ip                        = "fdd3:4686:2baa::5c73"
    cluster_ips = [
      "fdd3:4686:2baa::5c73",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
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
    cluster_ip                        = "fdd3:4686:2baa::6b84"
    cluster_ips = [
      "fdd3:4686:2baa::6b84",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
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
    cluster_ip                        = "fdd3:4686:2baa::e702"
    cluster_ips = [
      "fdd3:4686:2baa::e702",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
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
# kubernetes_service_v1.sampleapp__orders-rabbitmq:
resource "kubernetes_service_v1" "sampleapp__orders-rabbitmq" {
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
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "fdd3:4686:2baa::5e7"
    cluster_ips = [
      "fdd3:4686:2baa::5e7",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_class         = null
    load_balancer_ip            = null
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app.kubernetes.io/component" = "rabbitmq"
      "app.kubernetes.io/instance"  = "orders"
      "app.kubernetes.io/name"      = "orders"
    }
    session_affinity = "None"
    type             = "ClusterIP"

    port {
      app_protocol = null
      name         = "amqp"
      node_port    = 0
      port         = 5672
      protocol     = "TCP"
      target_port  = "amqp"
    }
    port {
      app_protocol = null
      name         = "http"
      node_port    = 0
      port         = 15672
      protocol     = "TCP"
      target_port  = "http"
    }
  }
}
# kubernetes_service_v1.sampleapp__orders:
resource "kubernetes_service_v1" "sampleapp__orders" {
  metadata {
    annotations   = {}
    generate_name = null
    labels = {
      "app.kuberneres.io/owner"      = "retail-store-sample"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/instance"   = "orders"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"       = "orders"
      "helm.sh/chart"                = "orders-0.8.4"
    }
    name      = "orders"
    namespace = kubernetes_namespace_v1.sampleapp.metadata[0].name
  }

  spec {
    allocate_load_balancer_node_ports = true
    cluster_ip                        = "fdd3:4686:2baa::5834"
    cluster_ips = [
      "fdd3:4686:2baa::5834",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = null
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_class         = null
    load_balancer_ip            = null
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app.kuberneres.io/owner"     = "retail-store-sample"
      "app.kubernetes.io/component" = "service"
      "app.kubernetes.io/instance"  = "orders"
      "app.kubernetes.io/name"      = "orders"
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
# kubernetes_service_v1.sampleapp__ui:
resource "kubernetes_service_v1" "sampleapp__ui" {
  metadata {
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-ip-address-type" = "dualstack"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
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
    cluster_ip                        = "fdd3:4686:2baa::25fe"
    cluster_ips = [
      "fdd3:4686:2baa::25fe",
    ]
    external_ips            = []
    external_name           = null
    external_traffic_policy = "Cluster"
    internal_traffic_policy = "Cluster"
    ip_families = [
      "IPv6",
    ]
    ip_family_policy            = "SingleStack"
    load_balancer_class         = "eks.amazonaws.com/nlb"
    load_balancer_ip            = null
    load_balancer_source_ranges = []
    publish_not_ready_addresses = false
    selector = {
      "app.kuberneres.io/owner"     = "retail-store-sample"
      "app.kubernetes.io/component" = "service"
      "app.kubernetes.io/instance"  = "ui"
      "app.kubernetes.io/name"      = "ui"
    }
    session_affinity = "None"
    type             = "LoadBalancer"

    port {
      app_protocol = null
      name         = "http"
      node_port    = 32375
      port         = 80
      protocol     = "TCP"
      target_port  = "http"
    }
  }
}
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
    service_name           = "catalog-mysql"

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
                name     = "catalog-db"
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
                name     = "catalog-db"
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
# kubernetes_stateful_set_v1.sampleapp__orders-rabbitmq:
resource "kubernetes_stateful_set_v1" "sampleapp__orders-rabbitmq" {

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
