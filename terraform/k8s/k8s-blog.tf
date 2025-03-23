resource "kubernetes_namespace_v1" "blog" {
  metadata {
    name = "blog"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "blog_claim" {
  metadata {
    name      = "blog-claim"
    namespace = kubernetes_namespace_v1.blog.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "azurefile-csi"

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
    namespace = kubernetes_namespace_v1.blog.metadata[0].name
    labels = {
      app = "blog"
    }
  }

  spec {
    replicas = 1

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
            claim_name = kubernetes_persistent_volume_claim_v1.blog_claim.metadata[0].name
          }
        }
        volume {
          name = "database-secrets"
          csi {
            driver    = "secrets-store.csi.k8s.io"
            read_only = true
            volume_attributes = {
              secretProviderClass = kubernetes_manifest.secrets_store_database.manifest.metadata.name
            }
          }
        }
        volume {
          name = "smtp-secrets"
          csi {
            driver    = "secrets-store.csi.k8s.io"
            read_only = true
            volume_attributes = {
              secretProviderClass = kubernetes_manifest.secrets_store_smtp.manifest.metadata.name
            }
          }
        }

        container {
          name              = "ghost"
          image             = "ghost:5"
          image_pull_policy = "Always"

          env {
            name  = "url"
            value = "http://drones-shuttles.org"
          }
          env {
            name  = "mail__from"
            value = "no-reply@mg.drones-shuttles.org"
          }
          env {
            name  = "mail__transport"
            value = "SMTP"
          }
          env {
            name  = "mail__options__service"
            value = "Mailgun"
          }
          env {
            name = "mail__options__auth__user"
            value_from {
              secret_key_ref {
                name = "smtp-connection"
                key  = "mail__options__auth__user"
              }
            }
          }
          env {
            name = "mail__options__auth__pass"
            value_from {
              secret_key_ref {
                name = "smtp-connection"
                key  = "mail__options__auth__pass"
              }
            }
          }
          env {
            name  = "database__client"
            value = "mysql"
          }
          env {
            name = "database__connection__host"
            value_from {
              secret_key_ref {
                name = "database-connection"
                key  = "database__connection__host"
              }
            }
          }
          env {
            name = "database__connection__user"
            value_from {
              secret_key_ref {
                name = "database-connection"
                key  = "database__connection__user"
              }
            }
          }
          env {
            name = "database__connection__password"
            value_from {
              secret_key_ref {
                name = "database-connection"
                key  = "database__connection__password"
              }
            }
          }
          env {
            name = "database__connection__database"
            value_from {
              secret_key_ref {
                name = "database-connection"
                key  = "database__connection__database"
              }
            }
          }
          env {
            name = "database__connection__ssl__ca"
            value_from {
              secret_key_ref {
                name = "database-connection"
                key  = "database__connection__ssl__ca"
              }
            }
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
          volume_mount {
            name       = "database-secrets"
            mount_path = "/mnt/database-secrets-store"
            read_only  = true
          }
          volume_mount {
            name       = "smtp-secrets"
            mount_path = "/mnt/smtp-secrets-store"
            read_only  = true
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

resource "kubernetes_horizontal_pod_autoscaler_v2" "blog" {
  metadata {
    name      = "blog-hpa"
    namespace = kubernetes_namespace_v1.blog.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.blog.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 3

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 60
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300
        select_policy                = "Min"
        policy {
          type           = "Percent"
          value          = 100
          period_seconds = 15
        }
      }
      scale_up {
        stabilization_window_seconds = 0
        select_policy                = "Max"
        policy {
          type           = "Percent"
          value          = 100
          period_seconds = 15
        }
      }
    }
  }
}
