resource "kubernetes_service_v1" "blog" {
  metadata {
    name      = "blog"
    namespace = kubernetes_namespace_v1.blog.metadata.name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "blog"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 2368
    }
  }
}
