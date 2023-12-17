resource "kubernetes_priority_class_v1" "low-priority" {
  metadata {
    name = "low-priority"
  }
  global_default = false
  value = -1
}


resource "kubernetes_priority_class_v1" "high-priority" {
  metadata {
    name = "high-priority"
  }
  global_default = false
  value = 1000000
}

