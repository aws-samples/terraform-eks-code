resource "kubernetes_namespace" "game1-2048" {
  metadata {
    name = "game1-2048"
  }

  timeouts {   
    delete = "20m"
  }
}

resource "kubernetes_namespace" "game2-2048" {
  metadata {
    name = "game2-2048"
  }

  timeouts {   
    delete = "20m"
  }
}

