# Sampleapp Namespace
# Creates a dedicated namespace for the retail store sample application
# Isolates application resources from other workloads

resource "kubernetes_namespace_v1" "sampleapp" {

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "sampleapp"
  }
}
