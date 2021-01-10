resource "kubernetes_namespace" "game-2048" {
  metadata {
    name = "game-2048"
  }

  timeouts {   
    delete = "20m"
  }
}

