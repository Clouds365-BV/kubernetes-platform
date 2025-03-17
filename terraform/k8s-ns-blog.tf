resource "kubernetes_namespace" "blog" {
  metadata {
    name = "blog"
  }
}