resource "kubernetes_namespace" "fargate1" {
  metadata {
    name = "fargate1"
  }

  timeouts {   
    delete = "20m"
  }
}

