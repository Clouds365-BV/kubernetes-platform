resource "kubernetes_namespace_v1" "admin" {
  metadata {
    name = "admin"
  }
}
