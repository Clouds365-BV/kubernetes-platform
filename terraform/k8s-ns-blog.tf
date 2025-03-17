resource "kubernetes_namespace" "blog" {
  metadata {
    name = "blog"
  }
}

resource "kubernetes_namespace" "drone" {
  metadata {
    name = "drone"
  }
}