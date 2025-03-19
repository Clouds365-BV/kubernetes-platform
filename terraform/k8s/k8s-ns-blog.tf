resource "kubernetes_namespace_v1" "blog" {
  metadata {
    name = "blog"
  }
}

resource "kubernetes_storage_class_v1" "azurefile" {
  metadata {
    name = "azurefile"
  }

  storage_provisioner = "kubernetes.io/azure-file"

  mount_options = [
    "dir_mode=0777",
    "file_mode=0777",
    "uid=1000",
    "gid=1000",
    "mfsymlinks",
    "nobrl",
    "cache=none"
  ]

  parameters = {
    skuName = "Standard_LRS"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "blog_claim" {
  metadata {
    name      = "blog-claim"
    namespace = "blog"
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "azurefile"

    resources {
      requests = {
        storage = "50Gi"
      }
    }
  }
}

resource "kubernetes_deployment_v1" "blog" {
  metadata {
    name      = "blog"
    namespace = "blog"
    labels = {
      app = "blog"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "blog"
      }
    }

    template {
      metadata {
        labels = {
          app = "blog"
        }
      }

      spec {
        volume {
          name = "blog-content"

          persistent_volume_claim {
            claim_name = "blog-claim"
          }
        }

        container {
          name  = "ghost"
          image = "ghost:alpine"

          env {
            name  = "url"
            value = "drones-shuttles.io"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 2368
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          volume_mount {
            name       = "blog-content"
            mount_path = "/var/lib/ghost/content"
          }

          resources {
            limits = {
              cpu    = "1"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }

          port {
            name           = "http"
            container_port = 2368
            protocol       = "TCP"
          }
        }

        restart_policy = "Always"
      }
    }
  }
}

resource "kubernetes_service_v1" "blog" {
  metadata {
    name      = "blog"
    namespace = "blog"
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

resource "kubernetes_ingress_v1" "ingress_blog" {
  metadata {
    name      = "ingress-blog"
    namespace = "blog"
    annotations = {
      "kubernetes.io/ingress.class"                   = "azure/application-gateway"
      "appgw.ingress.kubernetes.io/backend-protocol"  = "http"
      "appgw.ingress.kubernetes.io/ssl-redirect"      = "true"
      "appgw.ingress.kubernetes.io/request-body-size" = "16m"
    }
  }

  spec {
    rule {
      host = "drones-shuttles.io"

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
}
