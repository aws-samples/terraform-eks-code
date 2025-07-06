# kubernetes_namespace_v1.sampleapp:
resource "kubernetes_namespace_v1" "sampleapp" {

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "sampleapp"
  }
}
