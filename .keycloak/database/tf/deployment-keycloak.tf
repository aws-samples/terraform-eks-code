# kubernetes_deployment_v1.keycloak__keycloak:
resource "kubernetes_deployment_v1" "keycloak__keycloak" {

  metadata {
    annotations = {}
    labels = {
      "app" = "keycloak"
    }
    name      = "keycloak"
    namespace = "keycloak"
  }

  spec {
    min_ready_seconds         = 0
    paused                    = false
    progress_deadline_seconds = 600
    replicas                  = "1"
    revision_history_limit    = 10

    selector {
      match_labels = {
        "app" = "keycloak"
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
          "app" = "keycloak"
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
        share_process_namespace          = false
        termination_grace_period_seconds = 30

        container {
          args = [
            "start-dev",
          ]
          command                    = []
          image                      = "quay.io/keycloak/keycloak:20.0.3"
          image_pull_policy          = "IfNotPresent"
          name                       = "keycloak"
          stdin                      = false
          stdin_once                 = false
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          tty                        = false

          env {
            name  = "KEYCLOAK_ADMIN"
            value = "admin"
          }
          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = "keycloakpass123"
          }
          env {
            name  = "DB_VENDOR"
            value = "mysql"
          }
          env {
            name  = "DB_ADDR"
            value = "keycloak.cluster-czmq482okrhm.eu-west-1.rds.amazonaws.com"
          }
          env {
            name  = "DB_USERNAME"
            value = "admin"
          }
          env {
            name  = "DB_PASSWORD"
            value = "keycloakpass123"
          }
          env {
            name  = "DB_PORT"
            value = "3306"
          }
          env {
            name  = "DB_DATABASE"
            value = "keycloak"
          }
          env {
            name  = "KC_PROXY"
            value = "edge"
          }

          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          readiness_probe {
            failure_threshold     = 3
            initial_delay_seconds = 5
            period_seconds        = 3
            success_threshold     = 1
            timeout_seconds       = 1

            http_get {
              path   = "/realms/master"
              port   = "8080"
              scheme = "HTTP"
            }
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