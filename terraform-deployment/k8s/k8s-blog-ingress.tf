resource "kubernetes_ingress_v1" "ingress_blog_any_host" {
  metadata {
    name      = "ingress-blog-any-host"
    namespace = kubernetes_namespace_v1.blog.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                  = "azure/application-gateway"
      "appgw.ingress.kubernetes.io/backend-protocol" = "http"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/"
          backend {
            service {
              name = "blog"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_v1.blog
  ]
}
