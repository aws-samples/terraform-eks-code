resource "kubernetes_namespace" "appmesh-system" {
  metadata {
    name = "appmesh-system"
  }

  timeouts {   
    delete = "20m"
  }
}

